# Go Service Example

A minimal HTTP service using Go's standard library.

## Structure

```
go-service/
├── main.go          # Entry point and server setup
├── handlers.go      # HTTP handlers
├── handlers_test.go # Handler tests
└── README.md
```

## Usage

```bash
# Copy to your project
cp examples/go-service/*.go .

# Initialize go module (if not already done)
go mod init your-project

# Run the server
go run .

# Run tests
go test -v ./...
# Or use make
make test
```

## Key Patterns

### Handler Functions
```go
// handlers.go - Separate handlers from main
func handleHealth(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
```

### Testing with httptest
```go
// handlers_test.go
func TestHealthHandler(t *testing.T) {
    req := httptest.NewRequest("GET", "/health", nil)
    rec := httptest.NewRecorder()
    handleHealth(rec, req)
    // assertions...
}
```

### Clean Main
```go
// main.go - Just wiring
func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/health", handleHealth)
    http.ListenAndServe(":8080", mux)
}
```

## Extending

Add new endpoints:

1. Add handler function in `handlers.go`
2. Register route in `main.go`
3. Add tests in `handlers_test.go`

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/echo?msg=hello` | Echo message back |
| POST | `/echo` | Echo request body |
