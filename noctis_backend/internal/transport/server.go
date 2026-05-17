// Package transport wires Fiber HTTP and WebSocket handlers.
package transport

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	fws "github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	fiberlog "github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/Sliva2010/APKMES/noctis_backend/internal/auth"
	"github.com/Sliva2010/APKMES/noctis_backend/internal/messaging"
)

type Deps struct {
	Auth      *auth.Service
	Messaging *messaging.Service
	Logger    *zerolog.Logger
}

func NewServer(d Deps) *fiber.App {
	app := fiber.New(fiber.Config{
		AppName:               "noctis",
		DisableStartupMessage: true,
		ReadTimeout:           30 * time.Second,
		WriteTimeout:          30 * time.Second,
	})
	app.Use(recover.New())
	app.Use(cors.New())
	app.Use(fiberlog.New())

	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"ok": true, "service": "noctis"})
	})

	api := app.Group("/api/v1")
	registerAuthRoutes(api, d)
	registerChatRoutes(api, d)

	app.Get("/ws", fws.New(wsHandler(d)))

	return app
}

func registerAuthRoutes(g fiber.Router, d Deps) {
	g.Post("/auth/phone/start", func(c *fiber.Ctx) error {
		var body struct {
			Phone string `json:"phone"`
		}
		if err := c.BodyParser(&body); err != nil {
			return badReq(c, "BAD_BODY")
		}
		if err := d.Auth.StartPhone(c.Context(), body.Phone); err != nil {
			return errResp(c, err)
		}
		return c.JSON(fiber.Map{"ok": true})
	})

	g.Post("/auth/phone/verify", func(c *fiber.Ctx) error {
		var body struct {
			Phone string `json:"phone"`
			Code  string `json:"code"`
		}
		if err := c.BodyParser(&body); err != nil {
			return badReq(c, "BAD_BODY")
		}
		pair, err := d.Auth.VerifyPhone(c.Context(), body.Phone, body.Code)
		if err != nil {
			return errResp(c, err)
		}
		return c.JSON(pair)
	})

	g.Post("/auth/refresh", func(c *fiber.Ctx) error {
		var body struct {
			Refresh string `json:"refresh"`
		}
		if err := c.BodyParser(&body); err != nil {
			return badReq(c, "BAD_BODY")
		}
		pair, err := d.Auth.Refresh(c.Context(), body.Refresh)
		if err != nil {
			return errResp(c, err)
		}
		return c.JSON(pair)
	})
}

func registerChatRoutes(g fiber.Router, d Deps) {
	g.Use("/chats", authMiddleware(d.Auth))

	g.Get("/chats/:id/messages", func(c *fiber.Ctx) error {
		chatID, err := strconv.ParseInt(c.Params("id"), 10, 64)
		if err != nil {
			return badReq(c, "BAD_CHAT_ID")
		}
		limit, _ := strconv.Atoi(c.Query("limit", "50"))
		msgs, err := d.Messaging.History(c.Context(), chatID, limit)
		if err != nil {
			return errResp(c, err)
		}
		return c.JSON(fiber.Map{"messages": msgs})
	})

	g.Post("/chats/:id/messages", func(c *fiber.Ctx) error {
		chatID, err := strconv.ParseInt(c.Params("id"), 10, 64)
		if err != nil {
			return badReq(c, "BAD_CHAT_ID")
		}
		uid := c.Locals("uid").(int64)
		var body struct {
			ClientMessageID string `json:"client_message_id"`
			Body            string `json:"body"`
		}
		if err := c.BodyParser(&body); err != nil {
			return badReq(c, "BAD_BODY")
		}
		cmid, _ := uuid.Parse(body.ClientMessageID)
		m, err := d.Messaging.Send(c.Context(), messaging.SendInput{
			ChatID:          chatID,
			SenderID:        uid,
			ClientMessageID: cmid,
			BodyText:        body.Body,
		})
		if err != nil {
			return errResp(c, err)
		}
		return c.JSON(m)
	})
}

func authMiddleware(a *auth.Service) fiber.Handler {
	return func(c *fiber.Ctx) error {
		token := c.Get("Authorization")
		if len(token) > 7 && token[:7] == "Bearer " {
			token = token[7:]
		}
		uid, err := a.ParseAccess(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": fiber.Map{"code": "AUTH_REQUIRED"},
			})
		}
		c.Locals("uid", uid)
		return c.Next()
	}
}

func wsHandler(d Deps) func(*fws.Conn) {
	return func(c *fws.Conn) {
		token := c.Query("token")
		uid, err := d.Auth.ParseAccess(token)
		if err != nil {
			_ = c.WriteJSON(fiber.Map{"type": "error", "code": "AUTH_REQUIRED"})
			return
		}

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		// Subscribe to all incoming messages of the user's known chats.
		// MVP: client subscribes to chat IDs explicitly via a "subscribe" frame.
		subs := map[int64]context.CancelFunc{}
		defer func() {
			for _, fn := range subs {
				fn()
			}
		}()

		_ = c.WriteJSON(fiber.Map{"type": "auth.ok", "user_id": uid})

		for {
			_, raw, err := c.ReadMessage()
			if err != nil {
				return
			}
			var env struct {
				Type    string          `json:"type"`
				Payload json.RawMessage `json:"payload"`
			}
			if err := json.Unmarshal(raw, &env); err != nil {
				_ = c.WriteJSON(fiber.Map{"type": "error", "code": "PROTOCOL_VALIDATION_FAILED"})
				continue
			}

			switch env.Type {
			case "subscribe":
				var p struct {
					ChatID int64 `json:"chat_id"`
				}
				_ = json.Unmarshal(env.Payload, &p)
				if _, ok := subs[p.ChatID]; ok {
					continue
				}
				subCtx, subCancel := context.WithCancel(ctx)
				subs[p.ChatID] = subCancel
				go func(chatID int64) {
					ch, err := d.Messaging.Subscribe(subCtx, chatID)
					if err != nil {
						return
					}
					for m := range ch {
						_ = c.WriteJSON(fiber.Map{"type": "message.new", "payload": m})
					}
				}(p.ChatID)
			case "message.send":
				var p struct {
					ChatID          int64  `json:"chat_id"`
					ClientMessageID string `json:"client_message_id"`
					Body            string `json:"body"`
				}
				if err := json.Unmarshal(env.Payload, &p); err != nil {
					_ = c.WriteJSON(fiber.Map{"type": "error", "code": "PROTOCOL_VALIDATION_FAILED"})
					continue
				}
				cmid, _ := uuid.Parse(p.ClientMessageID)
				m, err := d.Messaging.Send(ctx, messaging.SendInput{
					ChatID:          p.ChatID,
					SenderID:        uid,
					ClientMessageID: cmid,
					BodyText:        p.Body,
				})
				if err != nil {
					_ = c.WriteJSON(fiber.Map{"type": "error", "code": "SEND_FAILED"})
					continue
				}
				_ = c.WriteJSON(fiber.Map{"type": "message.ack", "payload": m})
			default:
				_ = c.WriteJSON(fiber.Map{"type": "error", "code": "UNKNOWN_TYPE"})
			}
		}
	}
}

func badReq(c *fiber.Ctx, code string) error {
	return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
		"error": fiber.Map{"code": code},
	})
}

func errResp(c *fiber.Ctx, err error) error {
	switch {
	case errors.Is(err, auth.ErrInvalidPhone):
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": fiber.Map{"code": "INVALID_PHONE"},
		})
	case errors.Is(err, auth.ErrInvalidOTP):
		return c.Status(fiber.StatusUnprocessableEntity).JSON(fiber.Map{
			"error": fiber.Map{"code": "INVALID_OTP"},
		})
	case errors.Is(err, auth.ErrSessionInvalid):
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": fiber.Map{"code": "SESSION_INVALID"},
		})
	default:
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": fiber.Map{"code": "INTERNAL"},
		})
	}
}
