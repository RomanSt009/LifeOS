# Product Overview

**Status:** Draft  
**Version:** 0.1  
**Last updated:** 2026-08-09

## What is LifeOS?

LifeOS is a personal digital operating system that connects information, tasks, projects, files, knowledge and AI assistance.

## Problem

Modern digital life is fragmented.

Users commonly keep:

- notes in one application;
- files in another location;
- tasks in a task manager;
- events in a calendar;
- photos on their phone;
- documents in cloud storage;
- conversations in messaging applications.

These systems usually do not understand each other's context.

As a result, users spend time searching, copying information and manually maintaining relationships between data.

## Proposed Solution

LifeOS provides a unified environment where different types of information can exist as connected entities.

Instead of thinking:

> "Which application contains this information?"

the user should be able to think:

> "What information is related to this context?"

## Core Product Concepts

### Entity

An entity is a piece of information managed by LifeOS.

Examples:

- note;
- task;
- document;
- project;
- person;
- event;
- expense;
- image;
- bookmark.

### Relationship

Entities can be connected.

Example:

```text
Project
   |
   +-- Task
   |
   +-- Note
   |
   +-- Document
   |
   +-- Person
   |
   +-- Expense