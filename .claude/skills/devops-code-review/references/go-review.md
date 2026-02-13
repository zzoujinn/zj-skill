# Go Code Review Guidelines for DevOps

## Go Best Practices

### 1. Error Handling

```go
// GOOD - Explicit error handling
func deployService(name, namespace string) error {
    client, err := kubernetes.NewForConfig(config)
    if err != nil {
        return fmt.Errorf("failed to create client: %w", err)
    }

    deployment, err := client.AppsV1().Deployments(namespace).Get(
        context.Background(),
        name,
        metav1.GetOptions{},
    )
    if err != nil {
        if errors.IsNotFound(err) {
            return fmt.Errorf("deployment %s not found in namespace %s", name, namespace)
        }
        return fmt.Errorf("failed to get deployment: %w", err)
    }

    log.Printf("Found deployment: %s", deployment.Name)
    return nil
}

// BAD - Ignoring errors
func deployService(name, namespace string) {
    client, _ := kubernetes.NewForConfig(config)  // Error ignored
    deployment, _ := client.AppsV1().Deployments(namespace).Get(
        context.Background(),
        name,
        metav1.GetOptions{},
    )
    log.Printf("Found deployment: %s", deployment.Name)  // May panic
}

// BAD - Generic error messages
func deployService(name, namespace string) error {
    client, err := kubernetes.NewForConfig(config)
    if err != nil {
        return err  // No context
    }
    return nil
}
```

### 2. Context Usage

```go
// GOOD - Pass context for cancellation and timeouts
func fetchMetrics(ctx context.Context, url string) ([]byte, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, fmt.Errorf("failed to create request: %w", err)
    }

    client := &http.Client{Timeout: 30 * time.Second}
    resp, err := client.Do(req)
    if err != nil {
        return nil, fmt.Errorf("failed to fetch metrics: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
    }

    return io.ReadAll(resp.Body)
}

// Usage with timeout
ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()

metrics, err := fetchMetrics(ctx, "http://service/metrics")
if err != nil {
    log.Printf("Error: %v", err)
}

// BAD - No context
func fetchMetrics(url string) ([]byte, error) {
    resp, err := http.Get(url)  // No timeout, no cancellation
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    return io.ReadAll(resp.Body)
}
```

### 3. Resource Management

```go
// GOOD - Defer for cleanup
func processFile(filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        return fmt.Errorf("failed to open file: %w", err)
    }
    defer file.Close()  // Always closed

    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        processLine(scanner.Text())
    }

    return scanner.Err()
}

// GOOD - Multiple defers execute in LIFO order
func deploy(ctx context.Context) error {
    lock, err := acquireLock(ctx)
    if err != nil {
        return err
    }
    defer lock.Release()  // Released last

    conn, err := connectDB(ctx)
    if err != nil {
        return err
    }
    defer conn.Close()  // Released second

    tx, err := conn.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()  // Released first (if not committed)

    // Do work
    if err := doWork(tx); err != nil {
        return err
    }

    return tx.Commit()
}

// BAD - No cleanup
func processFile(filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        return err
    }
    // File never closed - resource leak

    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        processLine(scanner.Text())
    }
    return scanner.Err()
}
```

### 4. Goroutines and Concurrency

```go
// GOOD - Use WaitGroup for goroutine synchronization
func checkServices(services []string) []error {
    var wg sync.WaitGroup
    errChan := make(chan error, len(services))

    for _, service := range services {
        wg.Add(1)
        go func(svc string) {
            defer wg.Done()
            if err := checkService(svc); err != nil {
                errChan <- fmt.Errorf("service %s: %w", svc, err)
            }
        }(service)  // Pass service as parameter
    }

    wg.Wait()
    close(errChan)

    var errors []error
    for err := range errChan {
        errors = append(errors, err)
    }

    return errors
}

// GOOD - Use errgroup for error handling
import "golang.org/x/sync/errgroup"

func checkServices(ctx context.Context, services []string) error {
    g, ctx := errgroup.WithContext(ctx)

    for _, service := range services {
        service := service  // Capture loop variable
        g.Go(func() error {
            return checkService(ctx, service)
        })
    }

    return g.Wait()  // Returns first error
}

// BAD - Goroutine leak
func checkServices(services []string) {
    for _, service := range services {
        go func() {
            checkService(service)  // Wrong: captures loop variable
            // No way to know when done
        }()
    }
    // Returns immediately, goroutines may still be running
}

// BAD - Race condition
var counter int
for i := 0; i < 100; i++ {
    go func() {
        counter++  // Race condition
    }()
}

// GOOD - Use atomic or mutex
var counter int64
for i := 0; i < 100; i++ {
    go func() {
        atomic.AddInt64(&counter, 1)
    }()
}
```

### 5. Struct Design and Interfaces

```go
// GOOD - Small, focused interfaces
type Deployer interface {
    Deploy(ctx context.Context, app string) error
}

type HealthChecker interface {
    Check(ctx context.Context) error
}

// GOOD - Struct with validation
type DeploymentConfig struct {
    AppName   string
    Version   string
    Namespace string
    Replicas  int
    EnvVars   map[string]string
}

func NewDeploymentConfig(appName, version string) (*DeploymentConfig, error) {
    if appName == "" {
        return nil, errors.New("app name cannot be empty")
    }
    if version == "" {
        return nil, errors.New("version cannot be empty")
    }

    return &DeploymentConfig{
        AppName:   appName,
        Version:   version,
        Namespace: "default",
        Replicas:  3,
        EnvVars:   make(map[string]string),
    }, nil
}

func (c *DeploymentConfig) Validate() error {
    if c.Replicas < 1 {
        return errors.New("replicas must be at least 1")
    }
    if c.Namespace == "" {
        return errors.New("namespace cannot be empty")
    }
    return nil
}

// BAD - Large interface (violates ISP)
type Service interface {
    Deploy(ctx context.Context, app string) error
    Rollback(ctx context.Context, app string) error
    Scale(ctx context.Context, app string, replicas int) error
    GetLogs(ctx context.Context, app string) ([]string, error)
    GetMetrics(ctx context.Context, app string) (map[string]float64, error)
    // Too many methods
}

// BAD - No validation
type DeploymentConfig struct {
    AppName  string
    Version  string
    Replicas int
}
// No constructor, no validation
```

### 6. Configuration and Environment

```go
// GOOD - Configuration struct with validation
type Config struct {
    ServerPort    int           `env:"SERVER_PORT" envDefault:"8080"`
    DBHost        string        `env:"DB_HOST,required"`
    DBPort        int           `env:"DB_PORT" envDefault:"5432"`
    LogLevel      string        `env:"LOG_LEVEL" envDefault:"info"`
    ReadTimeout   time.Duration `env:"READ_TIMEOUT" envDefault:"30s"`
    WriteTimeout  time.Duration `env:"WRITE_TIMEOUT" envDefault:"30s"`
}

func LoadConfig() (*Config, error) {
    cfg := &Config{}
    if err := env.Parse(cfg); err != nil {
        return nil, fmt.Errorf("failed to parse config: %w", err)
    }

    if err := cfg.Validate(); err != nil {
        return nil, fmt.Errorf("invalid config: %w", err)
    }

    return cfg, nil
}

func (c *Config) Validate() error {
    if c.ServerPort < 1 || c.ServerPort > 65535 {
        return fmt.Errorf("invalid server port: %d", c.ServerPort)
    }

    validLevels := map[string]bool{"debug": true, "info": true, "warn": true, "error": true}
    if !validLevels[c.LogLevel] {
        return fmt.Errorf("invalid log level: %s", c.LogLevel)
    }

    return nil
}

// BAD - Direct environment variable access
func getConfig() {
    port := os.Getenv("PORT")  // No default, no validation
    host := os.Getenv("HOST")  // May be empty
    // Use directly without validation
}
```

### 7. Logging

```go
// GOOD - Structured logging with context
import (
    "go.uber.org/zap"
)

func deployService(ctx context.Context, name, version string) error {
    logger := zap.L().With(
        zap.String("service", name),
        zap.String("version", version),
        zap.String("trace_id", getTraceID(ctx)),
    )

    logger.Info("starting deployment")

    if err := performDeploy(ctx, name, version); err != nil {
        logger.Error("deployment failed",
            zap.Error(err),
            zap.Duration("duration", time.Since(start)),
        )
        return err
    }

    logger.Info("deployment successful",
        zap.Duration("duration", time.Since(start)),
    )
    return nil
}

// BAD - Unstructured logging
func deployService(name, version string) error {
    log.Printf("Deploying %s version %s", name, version)

    if err := performDeploy(name, version); err != nil {
        log.Printf("Error: %v", err)  // No context
        return err
    }

    log.Println("Success")  // No details
    return nil
}
```

### 8. Testing

```go
// GOOD - Table-driven tests
func TestValidateConfig(t *testing.T) {
    tests := []struct {
        name    string
        config  Config
        wantErr bool
    }{
        {
            name: "valid config",
            config: Config{
                ServerPort: 8080,
                DBHost:     "localhost",
                LogLevel:   "info",
            },
            wantErr: false,
        },
        {
            name: "invalid port",
            config: Config{
                ServerPort: 0,
                DBHost:     "localhost",
                LogLevel:   "info",
            },
            wantErr: true,
        },
        {
            name: "invalid log level",
            config: Config{
                ServerPort: 8080,
                DBHost:     "localhost",
                LogLevel:   "invalid",
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := tt.config.Validate()
            if (err != nil) != tt.wantErr {
                t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}

// GOOD - Use testify for assertions
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestDeployService(t *testing.T) {
    // Setup
    mockClient := &MockKubernetesClient{}
    deployer := NewDeployer(mockClient)

    // Execute
    err := deployer.Deploy(context.Background(), "myapp")

    // Assert
    require.NoError(t, err)
    assert.Equal(t, 1, mockClient.DeployCallCount())
}
```

### 9. HTTP Servers

```go
// GOOD - Graceful shutdown
func runServer(ctx context.Context, addr string, handler http.Handler) error {
    srv := &http.Server{
        Addr:         addr,
        Handler:      handler,
        ReadTimeout:  30 * time.Second,
        WriteTimeout: 30 * time.Second,
        IdleTimeout:  120 * time.Second,
    }

    // Start server in goroutine
    errChan := make(chan error, 1)
    go func() {
        log.Printf("Starting server on %s", addr)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            errChan <- err
        }
    }()

    // Wait for context cancellation or error
    select {
    case err := <-errChan:
        return err
    case <-ctx.Done():
        log.Println("Shutting down server...")

        // Graceful shutdown with timeout
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
        defer cancel()

        if err := srv.Shutdown(shutdownCtx); err != nil {
            return fmt.Errorf("server shutdown failed: %w", err)
        }

        log.Println("Server stopped gracefully")
        return nil
    }
}

// BAD - No graceful shutdown
func runServer(addr string, handler http.Handler) error {
    return http.ListenAndServe(addr, handler)  // Blocks forever
}
```

### 10. Metrics and Monitoring

```go
// GOOD - Prometheus metrics
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    deploymentCounter = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "deployments_total",
            Help: "Total number of deployments",
        },
        []string{"service", "status"},
    )

    deploymentDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "deployment_duration_seconds",
            Help:    "Deployment duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"service"},
    )
)

func deployService(ctx context.Context, service string) error {
    start := time.Now()

    err := performDeploy(ctx, service)

    duration := time.Since(start).Seconds()
    deploymentDuration.WithLabelValues(service).Observe(duration)

    status := "success"
    if err != nil {
        status = "failure"
    }
    deploymentCounter.WithLabelValues(service, status).Inc()

    return err
}
```

## Go DevOps Patterns

### 1. Retry with Exponential Backoff

```go
func retryWithBackoff(
    ctx context.Context,
    maxRetries int,
    initialDelay time.Duration,
    maxDelay time.Duration,
    fn func() error,
) error {
    delay := initialDelay

    for attempt := 0; attempt < maxRetries; attempt++ {
        err := fn()
        if err == nil {
            return nil
        }

        if attempt == maxRetries-1 {
            return fmt.Errorf("max retries exceeded: %w", err)
        }

        log.Printf("Attempt %d failed: %v. Retrying in %v...", attempt+1, err, delay)

        select {
        case <-time.After(delay):
            delay *= 2
            if delay > maxDelay {
                delay = maxDelay
            }
        case <-ctx.Done():
            return ctx.Err()
        }
    }

    return nil
}

// Usage
err := retryWithBackoff(
    ctx,
    5,
    1*time.Second,
    30*time.Second,
    func() error {
        return callAPI()
    },
)
```

### 2. Worker Pool

```go
type Job struct {
    ID   int
    Data string
}

type Result struct {
    Job   Job
    Error error
}

func workerPool(ctx context.Context, numWorkers int, jobs <-chan Job) <-chan Result {
    results := make(chan Result)

    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()

            for job := range jobs {
                select {
                case <-ctx.Done():
                    return
                default:
                    result := processJob(job)
                    results <- result
                }
            }
        }(i)
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}

func processJob(job Job) Result {
    // Process job
    err := doWork(job.Data)
    return Result{Job: job, Error: err}
}
```

### 3. Circuit Breaker

```go
type CircuitBreaker struct {
    maxFailures  int
    resetTimeout time.Duration
    mu           sync.Mutex
    failures     int
    lastFailTime time.Time
    state        string // "closed", "open", "half-open"
}

func NewCircuitBreaker(maxFailures int, resetTimeout time.Duration) *CircuitBreaker {
    return &CircuitBreaker{
        maxFailures:  maxFailures,
        resetTimeout: resetTimeout,
        state:        "closed",
    }
}

func (cb *CircuitBreaker) Call(fn func() error) error {
    cb.mu.Lock()

    if cb.state == "open" {
        if time.Since(cb.lastFailTime) > cb.resetTimeout {
            cb.state = "half-open"
            cb.failures = 0
        } else {
            cb.mu.Unlock()
            return errors.New("circuit breaker is open")
        }
    }

    cb.mu.Unlock()

    err := fn()

    cb.mu.Lock()
    defer cb.mu.Unlock()

    if err != nil {
        cb.failures++
        cb.lastFailTime = time.Now()

        if cb.failures >= cb.maxFailures {
            cb.state = "open"
        }

        return err
    }

    if cb.state == "half-open" {
        cb.state = "closed"
    }
    cb.failures = 0

    return nil
}
```

## Go Code Review Checklist

### Error Handling
- [ ] All errors are checked
- [ ] Errors are wrapped with context
- [ ] Error messages are descriptive
- [ ] No panic in library code
- [ ] Recover used appropriately

### Concurrency
- [ ] Goroutines are properly synchronized
- [ ] No goroutine leaks
- [ ] Context used for cancellation
- [ ] No race conditions
- [ ] Channels are properly closed

### Resource Management
- [ ] defer used for cleanup
- [ ] Files/connections are closed
- [ ] No resource leaks
- [ ] Timeouts configured

### Code Quality
- [ ] gofmt/goimports applied
- [ ] golangci-lint clean
- [ ] No unused variables/imports
- [ ] Proper naming conventions
- [ ] Comments for exported items

### Performance
- [ ] No unnecessary allocations
- [ ] Appropriate data structures
- [ ] Efficient algorithms
- [ ] Connection pooling
- [ ] Caching where appropriate

### Testing
- [ ] Unit tests present
- [ ] Table-driven tests
- [ ] Test coverage > 80%
- [ ] Benchmarks for critical paths
- [ ] Integration tests

### DevOps Specific
- [ ] Graceful shutdown
- [ ] Health checks
- [ ] Metrics collection
- [ ] Structured logging
- [ ] Configuration validation
- [ ] Retry logic
- [ ] Circuit breakers

## Go Tools

- **gofmt**: Code formatter
- **goimports**: Import organizer
- **golangci-lint**: Meta-linter
- **go vet**: Static analysis
- **gosec**: Security scanner
- **go test**: Testing
- **go test -race**: Race detector
- **pprof**: Profiler
