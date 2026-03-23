# Copyright (c) 2026 SUSE LLC
# Licensed under the terms of the MIT license.

@support/kubernetes.rb
Feature: Kubernetes connectivity and service discovery
  In order to ensure the Uyuni installation is healthy in Kubernetes
  As the administrator
  I want to verify that all pods can communicate with each other

  Scenario: Server can reach Database pod
    When I run "pg_isready -h uyuni-db -p 5432" on "server"
    Then I should see "accepting connections" in the output

  Scenario: Service Discovery works
    When I run "getent hosts uyuni-db" on "server"
    Then I should see "uyuni-db" in the output
    When I run "getent hosts uyuni-server" in the pod with label "app=uyuni-db"
    Then I should see "uyuni-server" in the output
