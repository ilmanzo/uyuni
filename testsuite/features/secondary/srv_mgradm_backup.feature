# Copyright (c) 2017-2026 SUSE LLC.
# Licensed under the terms of the MIT license.

@containerized_server
Feature: Validate that we can backup and restore the server
  As a system administrator
  I want to back up and restore my containerized Uyuni/SUSE Manager instance
  So that I can recover from system failures

# exclude the repository volume due to space constraints
  Scenario: Perform a test backup
    When I backup the server excluding the spacewalk volume
    Then the backup must exist

# stop the service before the restore, otherwise podman network creation will fail
  Scenario: Restore succeeds with force flag
    Given the backup must exist
    Then I stop the services on server
    And I successfully restore the backup

  Scenario: Remove backup and start services
    Given the backup must exist
    And I remove the backup directory on server
    Then I start the services on server
    And service "uyuni-server" is running on server
    And service "uyuni-db" is running on server
