import { DriveApiResponse, DriveFile } from '@/types/drive-types';

const GOOGLE_DRIVE_API_KEY = import.meta.env.VITE_GOOGLE_DRIVE_API_KEY || 'AIzaSyBnHPSdgv2Cc6wU38itY6YLriAb2g1_VQg';
const FOLDER_ID = '1qGzwJblLNfA9KBUlUzdXVa2mrw54lSbB';

export async function fetchGoogleDriveFiles(folderId?: string): Promise<DriveFile[]> {
  const targetFolderId = folderId || FOLDER_ID;
  
  try {
    const response = await fetch(
      `https://www.googleapis.com/drive/v3/files?q='${targetFolderId}'+in+parents&key=${GOOGLE_DRIVE_API_KEY}&fields=files(id,name,mimeType,size,webViewLink,webContentLink,parents)&orderBy=folder,name`
    );
    
    if (!response.ok) {
      throw new Error(`Failed to fetch files: ${response.status} ${response.statusText}`);
    }
    
    const data: DriveApiResponse = await response.json();
    return data.files || [];
  } catch (error) {
    console.error('Error fetching Google Drive files:', error);
    throw error;
  }
}

export async function fetchFolderInfo(folderId: string): Promise<{ name: string } | null> {
  try {
    const response = await fetch(
      `https://www.googleapis.com/drive/v3/files/${folderId}?key=${GOOGLE_DRIVE_API_KEY}&fields=name`
    );
    
    if (!response.ok) {
      return null;
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error fetching folder info:', error);
    return null;
  }
}

export function getFileType(mimeType: string): string {
  if (mimeType === 'application/vnd.google-apps.folder') return 'folder';
  if (mimeType.includes('video')) return 'video';
  if (mimeType.includes('pdf')) return 'pdf';
  if (mimeType.includes('image')) return 'image';
  if (mimeType.includes('document') || mimeType.includes('text')) return 'document';
  if (mimeType.includes('spreadsheet')) return 'spreadsheet';
  if (mimeType.includes('presentation')) return 'presentation';
  return 'other';
}

export function formatFileSize(bytes?: string): string {
  if (!bytes) return 'Unknown size';
  const size = parseInt(bytes);
  if (isNaN(size)) return 'Unknown size';
  
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(size) / Math.log(1024));
  return Math.round(size / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
}

export function getVideoUrl(fileId: string): string {
  // Use the embed preview URL which works better for streaming
  return `https://drive.google.com/file/d/${fileId}/preview`;
}

export function getVideoUrlAlternative(fileId: string): string {
  // Alternative direct download URL
  return `https://drive.google.com/uc?export=download&id=${fileId}&confirm=t`;
}

export function getVideoUrlEmbed(fileId: string): string {
  // Direct view URL as fallback
  return `https://drive.google.com/file/d/${fileId}/view`;
}

export function getPDFUrl(fileId: string): string {
  return `https://drive.google.com/file/d/${fileId}/preview`;
}
