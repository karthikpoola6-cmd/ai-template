package main

import (
	"encoding/json"
	"io"
	"net/http"
)

// HealthResponse represents the health check response.
type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version"`
}

// EchoResponse represents the echo response.
type EchoResponse struct {
	Message string `json:"message"`
	Method  string `json:"method"`
}

// handleHealth responds with service health status.
func handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := HealthResponse{
		Status:  "ok",
		Version: "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleEcho echoes back the message from query param or body.
func handleEcho(w http.ResponseWriter, r *http.Request) {
	var message string

	switch r.Method {
	case http.MethodGet:
		// Get message from query parameter
		message = r.URL.Query().Get("msg")
		if message == "" {
			message = "Hello, World!"
		}

	case http.MethodPost:
		// Get message from request body
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read body", http.StatusBadRequest)
			return
		}
		defer r.Body.Close()
		message = string(body)
		if message == "" {
			message = "Empty body"
		}

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := EchoResponse{
		Message: message,
		Method:  r.Method,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
