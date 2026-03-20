# Copyright (c) 2026 SUSE LLC
# Licensed under the terms of the MIT license.

@support/kubernetes.rb
Feature: Installation health and log integrity
  In order to ensure a clean installation
  As the administrator
  I want to verify that no critical errors occurred during pod startup

  Scenario: Server startup log audit
    Then the logs of pod with label "app=uyuni-server" should contain no startup errors

  Scenario: Database startup log audit
    Then the logs of pod with label "app=uyuni-db" should contain no startup errors

  Scenario: Proxy startup log audit
    Then the logs of pod with label "app=uyuni-proxy" should contain no startup errors
    And the logs of pod with label "app=uyuni-proxy" should contain the success string "Registration complete"
