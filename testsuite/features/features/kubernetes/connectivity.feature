# Copyright (c) 2026 SUSE LLC
# Licensed under the terms of the MIT license.

@support/kubernetes.rb
Feature: Kubernetes connectivity and service discovery
  In order to ensure the Uyuni installation is healthy in Kubernetes
  As the administrator
  I want to verify that all pods can communicate with each other

  Scenario: Server can reach Database pod
    When I run "pg_isready -h uyuni-db -p 5432" on "server"
    Then the output should contain "accepting connections"

  Scenario: Service Discovery works
    When I run "getent hosts uyuni-db" on "server"
    Then the output should contain "uyuni-db"
    When I run "getent hosts uyuni-server" on "db"
    Then the output should contain "uyuni-server"
