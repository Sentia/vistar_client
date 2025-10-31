#!/usr/bin/env ruby
# frozen_string_literal: true

# Manual test script for Sprint 1 Week 1 Review
require_relative 'lib/vistar_client'

puts "\n=== VistarClient Manual Testing ==="
puts "Version: #{VistarClient::VERSION}"

# Test 1: Create a client
puts "\n1. Creating a client..."
begin
  client = VistarClient::Client.new(
    api_key: 'test-api-key-123',
    network_id: 'test-network-456'
  )
  puts "   ✓ Client created successfully"
  puts "   - API Key: #{client.api_key}"
  puts "   - Network ID: #{client.network_id}"
  puts "   - API Base URL: #{client.api_base_url}"
  puts "   - Timeout: #{client.timeout}s"
rescue StandardError => e
  puts "   ✗ Failed: #{e.message}"
end

# Test 2: Client with custom config
puts "\n2. Creating client with custom config..."
begin
  custom_client = VistarClient::Client.new(
    api_key: 'custom-key',
    network_id: 'custom-net',
    api_base_url: 'https://staging.api.example.com',
    timeout: 30
  )
  puts "   ✓ Custom client created"
  puts "   - API Base URL: #{custom_client.api_base_url}"
  puts "   - Timeout: #{custom_client.timeout}s"
rescue StandardError => e
  puts "   ✗ Failed: #{e.message}"
end

# Test 3: Validation errors
puts "\n3. Testing validation..."
begin
  VistarClient::Client.new(api_key: nil, network_id: 'test')
  puts "   ✗ Should have raised ArgumentError"
rescue ArgumentError => e
  puts "   ✓ Correctly raised ArgumentError: #{e.message}"
end

# Test 4: Error classes
puts "\n4. Testing error classes..."
begin
  raise VistarClient::AuthenticationError, 'Invalid API key'
rescue VistarClient::Error => e
  puts "   ✓ AuthenticationError caught as VistarClient::Error"
  puts "   - Message: #{e.message}"
end

begin
  raise VistarClient::APIError.new('Bad request', status_code: 400, response_body: { 'error' => 'invalid' })
rescue VistarClient::APIError => e
  puts "   ✓ APIError with status code: #{e.status_code}"
  puts "   - Response body: #{e.response_body}"
end

begin
  raise VistarClient::ConnectionError, 'Network timeout'
rescue VistarClient::Error => e
  puts "   ✓ ConnectionError caught as VistarClient::Error"
end

# Test 5: Connection setup
puts "\n5. Testing Faraday connection..."
begin
  client = VistarClient::Client.new(
    api_key: 'test-key',
    network_id: 'test-net'
  )
  conn = client.send(:connection)
  puts "   ✓ Connection created: #{conn.class}"
  puts "   - URL prefix: #{conn.url_prefix}"
  puts "   - Has Authorization header: #{!conn.headers['Authorization'].nil?}"
  puts "   - Middleware count: #{conn.builder.handlers.length}"
rescue StandardError => e
  puts "   ✗ Failed: #{e.message}"
  puts "   #{e.backtrace.first(3).join("\n   ")}"
end

puts "\n=== All manual tests completed ==="
