// Package messaging implements direct chat messaging for NOCTIS MVP.
//
// Send is idempotent by (chat_id, sender_id, client_message_id) and
// assigns a strictly monotonic per-chat seq inside a single SQL statement.
// Real-time fanout uses Redis pub/sub channels named "chat_chan:<id>".
package messaging

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type Service struct {
	pg  *pgxpool.Pool
	rdb *redis.Client
}

func NewService(pg *pgxpool.Pool, rdb *redis.Client) *Service {
	return &Service{pg: pg, rdb: rdb}
}

// SendInput captures the request to deliver a text message.
type SendInput struct {
	ChatID          int64
	SenderID        int64
	ClientMessageID uuid.UUID
	BodyText        string
}

// Message is the persisted message representation.
type Message struct {
	ID        int64     `json:"id"`
	ChatID    int64     `json:"chat_id"`
	Seq       int64     `json:"seq"`
	SenderID  int64     `json:"sender_id"`
	BodyText  string    `json:"body"`
	CreatedAt time.Time `json:"created_at"`
}

// Send stores the message idempotently and broadcasts it via Redis Pub/Sub.
func (s *Service) Send(ctx context.Context, in SendInput) (Message, error) {
	if in.ClientMessageID == uuid.Nil {
		in.ClientMessageID = uuid.New()
	}
	const q = `
		WITH next AS (
			SELECT COALESCE(MAX(seq), 0) + 1 AS s
			FROM messages WHERE chat_id = $1
			FOR UPDATE
		)
		INSERT INTO messages (chat_id, seq, sender_id, client_message_id, body_text)
		SELECT $1, s, $2, $3, $4 FROM next
		ON CONFLICT (chat_id, sender_id, client_message_id)
		DO UPDATE SET edited_at = messages.edited_at
		RETURNING id, seq, created_at
	`
	var m Message = Message{ChatID: in.ChatID, SenderID: in.SenderID, BodyText: in.BodyText}
	row := s.pg.QueryRow(ctx, q, in.ChatID, in.SenderID, in.ClientMessageID, in.BodyText)
	if err := row.Scan(&m.ID, &m.Seq, &m.CreatedAt); err != nil {
		return Message{}, fmt.Errorf("send: %w", err)
	}
	payload, _ := json.Marshal(m)
	_ = s.rdb.Publish(ctx, fmt.Sprintf("chat_chan:%d", in.ChatID), payload).Err()
	return m, nil
}

// History returns the most recent messages of a chat (max 200).
func (s *Service) History(ctx context.Context, chatID int64, limit int) ([]Message, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	rows, err := s.pg.Query(ctx, `
		SELECT id, chat_id, seq, sender_id, COALESCE(body_text, ''), created_at
		FROM messages
		WHERE chat_id = $1 AND deleted_for_all_at IS NULL
		ORDER BY id DESC
		LIMIT $2
	`, chatID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := make([]Message, 0, limit)
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.ChatID, &m.Seq, &m.SenderID, &m.BodyText, &m.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// Subscribe yields messages broadcast for a specific chat.
// The returned channel is closed when ctx is canceled.
func (s *Service) Subscribe(ctx context.Context, chatID int64) (<-chan Message, error) {
	sub := s.rdb.Subscribe(ctx, fmt.Sprintf("chat_chan:%d", chatID))
	if _, err := sub.Receive(ctx); err != nil {
		return nil, err
	}
	out := make(chan Message, 16)
	go func() {
		defer close(out)
		defer func() { _ = sub.Close() }()
		ch := sub.Channel()
		for {
			select {
			case <-ctx.Done():
				return
			case msg, ok := <-ch:
				if !ok {
					return
				}
				var m Message
				if err := json.Unmarshal([]byte(msg.Payload), &m); err == nil {
					out <- m
				}
			}
		}
	}()
	return out, nil
}
