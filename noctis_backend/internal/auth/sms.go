package auth

import (
	"context"

	"github.com/rs/zerolog/log"
)

// NewSMSSender returns the configured SMS sender. For MVP only the
// "mock" provider is wired in; production providers (twilio, smsru)
// can be added without changing call sites.
func NewSMSSender(name string) SMSSender {
	switch name {
	default:
		return &mockSender{}
	}
}

type mockSender struct{}

func (m *mockSender) Send(ctx context.Context, phone, message string) error {
	log.Info().Str("phone", phone).Str("body", message).Msg("sms.mock send")
	return nil
}
