import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { DriveFile } from '@/types/drive-types';
import { getFileType, formatFileSize } from '@/services/google-drive';
import {
  Play,
  FileText,
  Image as ImageIcon,
  File,
  FileSpreadsheet,
  Presentation,
  Folder,
  ExternalLink,
  Eye,
  ZoomIn,
  Video
} from 'lucide-react';

interface FileCardProps {
  file: DriveFile;
  onOpenVideo: (file: DriveFile) => void;
  onOpenPDF: (file: DriveFile) => void;
  onOpenImage: (file: DriveFile) => void;
  onOpenFolder: (file: DriveFile) => void;
}

export default function FileCard({
  file,
  onOpenVideo,
  onOpenPDF,
  onOpenImage,
  onOpenFolder
}: FileCardProps) {
  const fileType = getFileType(file.mimeType);
  const fileSize = formatFileSize(file.size);

  const getFileIcon = () => {
    switch (fileType) {
      case 'folder':
        return <Folder className="w-10 h-10 text-primary" />;
      case 'video':
        return <Video className="w-10 h-10 text-accent" />;
      case 'pdf':
        return <FileText className="w-10 h-10 text-red-400" />;
      case 'image':
        return <ImageIcon className="w-10 h-10 text-emerald-400" />;
      case 'document':
        return <FileText className="w-10 h-10 text-blue-400" />;
      case 'spreadsheet':
        return <FileSpreadsheet className="w-10 h-10 text-green-500" />;
      case 'presentation':
        return <Presentation className="w-10 h-10 text-orange-400" />;
      default:
        return <File className="w-10 h-10 text-gray-400" />;
    }
  };

  const onCardClick = () => {
    switch (fileType) {
      case 'folder':
        onOpenFolder(file);
        break;
      case 'video':
        onOpenVideo(file);
        break;
      case 'pdf':
        onOpenPDF(file);
        break;
      case 'image':
        onOpenImage(file);
        break;
      default:
        // Fallback to drive
        if (file.webViewLink) window.open(file.webViewLink, '_blank');
        break;
    }
  };

  return (
    <Card
      className="glass-card overflow-hidden group border-0 cursor-pointer relative"
      onClick={onCardClick}
    >
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-accent/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

      <CardContent className="p-5 font-medium relative z-10 flex flex-col h-full min-h-[160px] justify-between">
        <div className="flex items-start justify-between">
          <div className="p-3 rounded-2xl bg-white/5 border border-white/5 group-hover:scale-110 group-hover:bg-white/10 transition-all duration-300">
            {getFileIcon()}
          </div>

          {fileType === 'video' && (
            <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center opacity-0 group-hover:opacity-100 transform translate-y-2 group-hover:translate-y-0 transition-all">
              <Play className="w-4 h-4 text-white fill-white" />
            </div>
          )}
        </div>

        <div className="mt-4">
          <h3
            className="font-semibold text-white text-lg mb-1 truncate leading-tight group-hover:text-primary transition-colors"
            title={file.name}
            data-testid={`text-filename-${file.id}`}
          >
            {file.name}
          </h3>
          <p
            className="text-xs text-white/40 font-mono"
            data-testid={`text-filesize-${file.id}`}
          >
            {fileSize}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}
