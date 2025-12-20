export interface DriveFile {
  id: string;
  name: string;
  mimeType: string;
  size?: string;
  webViewLink?: string;
  webContentLink?: string;
  parents?: string[];
}

export interface DriveApiResponse {
  files: DriveFile[];
}

export type FileType = 'video' | 'pdf' | 'image' | 'document' | 'spreadsheet' | 'presentation' | 'folder' | 'other';

export interface FolderBreadcrumb {
  id: string;
  name: string;
}
