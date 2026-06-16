// Package migrations embeds the SQL migration files so the API binary and the
// migrate CLI can apply them without the files being present on disk.
package migrations

import "embed"

//go:embed *.sql
var FS embed.FS
