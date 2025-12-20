# Replit.md

## Overview

Delta2zero is a file viewer application that provides secure access to Google Drive files through a password-protected interface. The application allows users to view various file types including videos, PDFs, images, and documents in modal viewers. It features a modern React frontend with a Node.js/Express backend, designed for easy deployment and scalability.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
- **React SPA**: Single-page application built with React 18+ using TypeScript
- **Routing**: Uses Wouter for lightweight client-side routing
- **State Management**: TanStack Query (React Query) for server state management and caching
- **UI Framework**: Shadcn/ui components built on Radix UI primitives with Tailwind CSS
- **Build Tool**: Vite for fast development and optimized production builds

### Backend Architecture
- **Express Server**: Node.js REST API server with TypeScript
- **Static File Serving**: Serves the React build in production with Vite middleware in development
- **Database Ready**: Configured for PostgreSQL with Drizzle ORM, though currently using in-memory storage
- **File Structure**: Monorepo structure with shared types and schemas between client and server

### Authentication & Security
- **Simple Password Protection**: Basic access code authentication ("delta2025")
- **Session Management**: Client-side state management for authentication status
- **No User Registration**: Single access code for all users

### File Management
- **Google Drive Integration**: Direct integration with Google Drive API v3
- **File Type Support**: Videos, PDFs, images, documents, spreadsheets, and presentations
- **Modal Viewers**: Dedicated modal components for different file types
- **Direct Streaming**: Files are served directly from Google Drive without local storage

### Data Storage
- **Current**: In-memory storage with basic user interface defined
- **Future Ready**: Drizzle ORM configured for PostgreSQL migration
- **Schema**: User model with username/password fields prepared for database implementation

### External Dependencies
- **Google Drive API**: File listing and access via public API key
- **Radix UI**: Accessible component primitives for UI elements
- **Tailwind CSS**: Utility-first CSS framework for styling
- **TanStack Query**: Data fetching and caching library
- **React Hook Form**: Form validation and management

## External Dependencies

### Core Services
- **Google Drive API v3**: File listing and content access
  - API Key: Hard-coded in environment
  - Folder ID: Specific Google Drive folder for file access
  - Public read access to designated folder

### UI Libraries
- **Radix UI**: Complete set of accessible component primitives
- **Tailwind CSS**: Utility-first CSS framework with custom design tokens
- **Lucide React**: Icon library for consistent iconography

### Development Tools
- **Vite**: Build tool and development server
- **TypeScript**: Type safety across the entire application
- **ESBuild**: Fast JavaScript bundler for production builds

### Database (Configured but not active)
- **PostgreSQL**: Prepared for future user management
- **Drizzle ORM**: Type-safe database operations
- **Neon Database**: Cloud PostgreSQL provider ready for deployment

### Deployment
- **Replit**: Optimized for Replit deployment with specific plugins
- **Node.js**: Runtime environment for the Express server
- **Environment Variables**: DATABASE_URL and Google Drive API configuration