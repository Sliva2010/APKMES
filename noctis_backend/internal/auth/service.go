// Package auth implements phone-OTP authentication for NOCTIS.
//
// MVP scope (R1, R3 partially):
//   - StartPhone   — issues a 6-digit OTP, stores its hash in Redis with 5m TTL.
//   - VerifyPhone  — checks the code, creates the user if needed, returns JWT pair.
//   - Refresh      — exchanges a refresh token for a new access token.
//
// SMS delivery is abstracted by SMSSender. The "mock" provider simply logs
// the OTP to stdout — useful for CI and local development.
package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"regexp"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
)

var phoneRegex = regexp.MustCompile(`^\+[1-9]\d{7,14}$`)

// SMSSender is implemented by concrete SMS providers (twilio, smsru, mock).
type SMSSender interface {
	Send(ctx context.Context, phone, message string) error
}

type Service struct {
	pg      *pgxpool.Pool
	rdb     *redis.Client
	jwtKey  []byte
	smsName string
	sms     SMSSender
}

func NewService(pg *pgxpool.Pool, rdb *redis.Client, jwtKey []byte, smsName string) *Service {
	return &Service{
		pg:      pg,
		rdb:     rdb,
		jwtKey:  jwtKey,
		smsName: smsName,
		sms:     NewSMSSender(smsName),
	}
}

// StartPhone generates an OTP, stores it in Redis (sha256(code) keyed by phone),
// and dispatches it via the configured SMS provider.
func (s *Service) StartPhone(ctx context.Context, phone string) error {
	if !phoneRegex.MatchString(phone) {
		return ErrInvalidPhone
	}
	code, err := genOTP()
	if err != nil {
		return err
	}
	hash := sha256.Sum256([]byte(code))
	key := "otp:phone:" + phone
	if err := s.rdb.Set(ctx, key, hex.EncodeToString(hash[:]), 5*time.Minute).Err(); err != nil {
		return fmt.Errorf("redis: %w", err)
	}
	if err := s.sms.Send(ctx, phone, "NOCTIS code: "+code); err != nil {
		return fmt.Errorf("sms: %w", err)
	}
	return nil
}

// VerifyPhone checks the supplied OTP and on success returns access+refresh tokens.
func (s *Service) VerifyPhone(ctx context.Context, phone, code string) (TokenPair, error) {
	if !phoneRegex.MatchString(phone) {
		return TokenPair{}, ErrInvalidPhone
	}
	key := "otp:phone:" + phone
	stored, err := s.rdb.Get(ctx, key).Result()
	if err != nil {
		return TokenPair{}, ErrInvalidOTP
	}
	hash := sha256.Sum256([]byte(code))
	if hex.EncodeToString(hash[:]) != stored {
		return TokenPair{}, ErrInvalidOTP
	}
	_ = s.rdb.Del(ctx, key).Err()

	uid, err := s.upsertUser(ctx, phone)
	if err != nil {
		return TokenPair{}, err
	}
	return s.issueTokens(ctx, uid)
}

// Refresh issues a new access token if the refresh token is still valid.
func (s *Service) Refresh(ctx context.Context, refresh string) (TokenPair, error) {
	hash := sha256.Sum256([]byte(refresh))
	key := "refresh:" + hex.EncodeToString(hash[:])
	uidStr, err := s.rdb.Get(ctx, key).Result()
	if err != nil {
		return TokenPair{}, ErrSessionInvalid
	}
	var uid int64
	if _, err := fmt.Sscan(uidStr, &uid); err != nil {
		return TokenPair{}, ErrSessionInvalid
	}
	return s.issueTokens(ctx, uid)
}

func (s *Service) upsertUser(ctx context.Context, phone string) (int64, error) {
	var id int64
	err := s.pg.QueryRow(ctx, `
		INSERT INTO users (phone_e164)
		VALUES ($1)
		ON CONFLICT (phone_e164) DO UPDATE SET updated_at = now()
		RETURNING id
	`, phone).Scan(&id)
	if err != nil {
		return 0, fmt.Errorf("upsert user: %w", err)
	}
	return id, nil
}

func (s *Service) issueTokens(ctx context.Context, uid int64) (TokenPair, error) {
	now := time.Now()
	access := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": uid,
		"iat": now.Unix(),
		"exp": now.Add(time.Hour).Unix(),
	})
	accessStr, err := access.SignedString(s.jwtKey)
	if err != nil {
		return TokenPair{}, fmt.Errorf("sign access: %w", err)
	}
	refreshBytes := make([]byte, 32)
	if _, err := rand.Read(refreshBytes); err != nil {
		return TokenPair{}, err
	}
	refresh := hex.EncodeToString(refreshBytes)
	hash := sha256.Sum256([]byte(refresh))
	if err := s.rdb.Set(ctx, "refresh:"+hex.EncodeToString(hash[:]),
		fmt.Sprintf("%d", uid), 30*24*time.Hour).Err(); err != nil {
		return TokenPair{}, fmt.Errorf("store refresh: %w", err)
	}
	log.Debug().Int64("user_id", uid).Msg("auth: tokens issued")
	return TokenPair{Access: accessStr, Refresh: refresh, UserID: uid}, nil
}

// ParseAccess validates the JWT and returns the user ID claim.
func (s *Service) ParseAccess(token string) (int64, error) {
	parsed, err := jwt.Parse(token, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.jwtKey, nil
	})
	if err != nil || !parsed.Valid {
		return 0, ErrSessionInvalid
	}
	claims, ok := parsed.Claims.(jwt.MapClaims)
	if !ok {
		return 0, ErrSessionInvalid
	}
	switch v := claims["sub"].(type) {
	case float64:
		return int64(v), nil
	case int64:
		return v, nil
	default:
		return 0, ErrSessionInvalid
	}
}

func genOTP() (string, error) {
	max := big.NewInt(1_000_000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

type TokenPair struct {
	Access  string `json:"access"`
	Refresh string `json:"refresh"`
	UserID  int64  `json:"user_id"`
}

var (
	ErrInvalidPhone   = errors.New("INVALID_PHONE")
	ErrInvalidOTP     = errors.New("INVALID_OTP")
	ErrSessionInvalid = errors.New("SESSION_INVALID")
)
