package runcontext

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"github.com/redhat-appstudio/helmet/internal/chartfs"
	"github.com/redhat-appstudio/helmet/internal/config"
	"github.com/redhat-appstudio/helmet/internal/k8s"
)

// RunContext carries runtime dependencies for command execution: Kubernetes client,
// chart filesystem, logger, and cluster configuration (fetched on demand via GetConfig).
type RunContext struct {
	Kube    *k8s.Kube
	ChartFS *chartfs.ChartFS
	Logger  *slog.Logger

	// Config is the cluster configuration, populated by GetConfig on first use.
	Config *config.Config

	appName string // installer name, for GetConfig error message
}

// NewRunContext builds a RunContext with the given app name, kube, chart filesystem,
// and logger. Config is left nil until GetConfig is called.
func NewRunContext(
	appName string,
	kube *k8s.Kube,
	cfs *chartfs.ChartFS,
	logger *slog.Logger,
) *RunContext {
	return &RunContext{
		Kube:    kube,
		ChartFS: cfs,
		Logger:  logger,
		appName: appName,
	}
}

// GetConfig returns the cluster configuration, fetching it from the cluster if
// not already loaded. On fetch failure, a message is printed to stderr and an
// error is returned.
func (rc *RunContext) GetConfig(ctx context.Context) (*config.Config, error) {
	if rc.Config != nil {
		return rc.Config, nil
	}
	mgr := config.NewConfigMapManager(rc.Kube, rc.appName)
	cfg, err := mgr.GetConfig(ctx)
	if err != nil {
		fmt.Fprintf(os.Stderr, `
Unable to find the configuration in the cluster, or the configuration is invalid.
Please refer to the subcommand "%s config" to manage installer's
configuration for the target cluster.

	$ %s config --help
		`, rc.appName, rc.appName)
		return nil, err
	}
	rc.Config = cfg
	return rc.Config, nil
}
