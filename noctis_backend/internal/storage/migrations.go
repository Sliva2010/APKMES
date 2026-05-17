// In-process schema migrations.
// For NOCTIS MVP we keep a single embedded SQL file and apply
// it idempotently. A proper migration tool (goose) is planned in tasks 3.x
// but is not required to bootstrap the service.
package storage

import (
	"context"
	_ "embed"

	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed schema.sql
var schemaSQL string

func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, schemaSQL)
	return err
}
