# Copyright (c) 2026 SUSE LLC
# Licensed under the terms of the MIT license.

@support/kubernetes.rb
Feature: Database resiliency and data persistence
  In order to ensure that no data is lost during pod failures
  As the administrator
  I want to verify that data survives a database pod restart

  Scenario: Data persists after Database pod restart
    Given I am on the "Organizations" page
    And I follow "Create Organization"
    And I enter "PersistenceTestOrg" as "orgName"
    And I enter "persistence-admin" as "adminName"
    And I enter "linux" as "adminPassword"
    And I enter "linux" as "adminPasswordConfirm"
    And I enter "galaxy-noise@localhost" as "adminEmail"
    And I select "Mr." from "prefix"
    And I enter "Persistence" as "firstNames"
    And I enter "Admin" as "lastName"
    And I click on "Create Organization"
    Then I should see a "Organization PersistenceTestOrg created" text
    When I delete the pod with label "app=uyuni-db"
    And I wait until the pod with label "app=uyuni-db" is running
    And I wait until the pod with label "app=uyuni-db" is ready
    And I wait until the pod with label "app=uyuni-server" is ready
    Then I am on the "Organizations" page
    And I should see a "PersistenceTestOrg" link
