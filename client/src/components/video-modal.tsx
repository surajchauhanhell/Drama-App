import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { DriveFile } from '@/types/drive-types';
import { getVideoUrl } from '@/services/google-drive';

interface VideoModalProps {
  file: DriveFile | null;
  isOpen: boolean;
  onClose: () => void;
}

export default function VideoModal({ file, isOpen, onClose }: VideoModalProps) {
  const [videoError, setVideoError] = useState(false);

  const handleVideoError = () => {
    setVideoError(true);
  };

  const handleOpenChange = (open: boolean) => {
    if (!open) {
      onClose();
      setVideoError(false);
    }
  };

  if (!file) return null;

  const videoSrc = getVideoUrl(file.id);

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] p-0">
        <DialogHeader className="p-4 border-b">
          <DialogTitle data-testid="text-video-title">{file.name}</DialogTitle>
        </DialogHeader>
        <div className="p-4">
          <div className="video-player bg-black rounded-lg overflow-hidden">
            {videoError ? (
              <div className="flex items-center justify-center h-64 text-white">
                <div className="text-center">
                  <p className="mb-2">Unable to play video</p>
                  <p className="text-sm text-gray-300">
                    The video format may not be supported or there was an error loading the file.
                  </p>
                </div>
              </div>
            ) : (
              <video 
                controls 
                className="w-full h-auto max-h-[60vh]"
                onError={handleVideoError}
                data-testid="video-player"
                key={file.id} // Force re-mount when file changes
              >
                <source src={videoSrc} type="video/mp4" />
                <source src={videoSrc} type="video/webm" />
                <source src={videoSrc} type="video/ogg" />
                Your browser does not support the video tag.
              </video>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
