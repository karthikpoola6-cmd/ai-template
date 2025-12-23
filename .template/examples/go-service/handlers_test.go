package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	tests := []struct {
		name       string
		method     string
		wantStatus int
		wantBody   string
	}{
		{
			name:       "GET returns ok",
			method:     http.MethodGet,
			wantStatus: http.StatusOK,
			wantBody:   "ok",
		},
		{
			name:       "POST not allowed",
			method:     http.MethodPost,
			wantStatus: http.StatusMethodNotAllowed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/health", nil)
			rec := httptest.NewRecorder()

			handleHealth(rec, req)

			if rec.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d", rec.Code, tt.wantStatus)
			}

			if tt.wantBody != "" {
				var response HealthResponse
				if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if response.Status != tt.wantBody {
					t.Errorf("status = %q, want %q", response.Status, tt.wantBody)
				}
			}
		})
	}
}

func TestHealthHandlerResponse(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	handleHealth(rec, req)

	// Check content type
	contentType := rec.Header().Get("Content-Type")
	if contentType != "application/json" {
		t.Errorf("Content-Type = %q, want application/json", contentType)
	}

	// Check response structure
	var response HealthResponse
	if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if response.Status != "ok" {
		t.Errorf("status = %q, want ok", response.Status)
	}
	if response.Version == "" {
		t.Error("version should not be empty")
	}
}

func TestEchoHandler(t *testing.T) {
	tests := []struct {
		name        string
		method      string
		query       string
		body        string
		wantStatus  int
		wantMessage string
	}{
		{
			name:        "GET with query param",
			method:      http.MethodGet,
			query:       "?msg=hello",
			wantStatus:  http.StatusOK,
			wantMessage: "hello",
		},
		{
			name:        "GET without query param",
			method:      http.MethodGet,
			query:       "",
			wantStatus:  http.StatusOK,
			wantMessage: "Hello, World!",
		},
		{
			name:        "POST with body",
			method:      http.MethodPost,
			body:        "test message",
			wantStatus:  http.StatusOK,
			wantMessage: "test message",
		},
		{
			name:        "POST empty body",
			method:      http.MethodPost,
			body:        "",
			wantStatus:  http.StatusOK,
			wantMessage: "Empty body",
		},
		{
			name:       "PUT not allowed",
			method:     http.MethodPut,
			wantStatus: http.StatusMethodNotAllowed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var req *http.Request
			if tt.body != "" {
				req = httptest.NewRequest(tt.method, "/echo"+tt.query, strings.NewReader(tt.body))
			} else {
				req = httptest.NewRequest(tt.method, "/echo"+tt.query, nil)
			}
			rec := httptest.NewRecorder()

			handleEcho(rec, req)

			if rec.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d", rec.Code, tt.wantStatus)
			}

			if tt.wantMessage != "" {
				var response EchoResponse
				if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if response.Message != tt.wantMessage {
					t.Errorf("message = %q, want %q", response.Message, tt.wantMessage)
				}
				if response.Method != tt.method {
					t.Errorf("method = %q, want %q", response.Method, tt.method)
				}
			}
		})
	}
}
