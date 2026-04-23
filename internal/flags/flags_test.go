package flags

import (
	"testing"

	"github.com/spf13/pflag"
)

func TestPersistentFlags_VerboseRegistered(t *testing.T) {
	f := NewFlags()
	fs := pflag.NewFlagSet("test", pflag.ContinueOnError)
	f.PersistentFlags(fs)

	flag := fs.Lookup("verbose")
	if flag == nil {
		t.Fatal(`expected persistent flag "verbose"`)
	}
	if flag.Shorthand != "v" {
		t.Errorf("shorthand: got %q, want %q", flag.Shorthand, "v")
	}
	if flag.DefValue != "false" {
		t.Errorf("DefValue: got %q, want %q", flag.DefValue, "false")
	}
}
