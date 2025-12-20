import { useState, useEffect, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { DriveFile } from '@/types/drive-types';
import { getVideoUrlEmbed } from '@/services/google-drive';
import {
  List,
  X,
  RefreshCw,
  ExternalLink,
  SkipBack,
  SkipForward,
  Maximize,
  RotateCcw,
  RotateCw
} from 'lucide-react';

interface VideoPlaylistProps {
  files: DriveFile[];
  initialVideoId?: string;
  isOpen: boolean;
  onClose: () => void;
}

export default function VideoPlaylist({ files, initialVideoId, isOpen, onClose }: VideoPlaylistProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const videoFiles = files;
  const [currentVideoIndex, setCurrentVideoIndex] = useState(0);
  const [showPlaylist, setShowPlaylist] = useState(true);
  const [videoError, setVideoError] = useState(false);
  const [currentVideoUrl, setCurrentVideoUrl] = useState('');
  const [urlAttempt, setUrlAttempt] = useState(0);
  const [isRetrying, setIsRetrying] = useState(false);

  const currentVideo = videoFiles[currentVideoIndex];

  // Find initial video index
  useEffect(() => {
    if (initialVideoId) {
      const index = videoFiles.findIndex(file => file.id === initialVideoId);
      if (index !== -1) {
        setCurrentVideoIndex(index);
      }
    }
  }, [initialVideoId, videoFiles]);

  // Update video URL when current video changes
  useEffect(() => {
    if (currentVideo) {
      setCurrentVideoUrl(`https://drive.google.com/file/d/${currentVideo.id}/preview?quality=hd1080`);
      setUrlAttempt(0);
      setVideoError(false);
    }
  }, [currentVideo]);

  const handleVideoError = async () => {
    console.log(`Video error on attempt ${urlAttempt + 1} for video:`, currentVideo?.name);

    if (urlAttempt === 0) {
      setCurrentVideoUrl(`https://drive.google.com/file/d/${currentVideo.id}/preview?quality=hd720`);
      setUrlAttempt(1);
    } else if (urlAttempt === 1) {
      setCurrentVideoUrl(`https://drive.google.com/file/d/${currentVideo.id}/preview`);
      setUrlAttempt(2);
    } else if (urlAttempt === 2) {
      setCurrentVideoUrl(getVideoUrlEmbed(currentVideo.id));
      setUrlAttempt(3);
    } else {
      setVideoError(true);
    }
  };

  const handleVideoLoad = () => {
    setVideoError(false);
    setIsRetrying(false);
    console.log('Video loaded successfully');
  };

  const retryVideo = () => {
    setIsRetrying(true);
    setVideoError(false);
    setUrlAttempt(0);
    setCurrentVideoUrl(`https://drive.google.com/file/d/${currentVideo.id}/preview?quality=hd1080`);
  };

  const playNext = () => {
    if (currentVideoIndex < videoFiles.length - 1) {
      setCurrentVideoIndex(currentVideoIndex + 1);
    }
  };

  const playPrevious = () => {
    if (currentVideoIndex > 0) {
      setCurrentVideoIndex(currentVideoIndex - 1);
    }
  };

  const selectVideo = (index: number) => {
    setCurrentVideoIndex(index);
  };

  const toggleFullscreen = () => {
    if (videoRef.current) {
      if (document.fullscreenElement) {
        document.exitFullscreen();
      } else {
        videoRef.current.requestFullscreen().catch(err => {
          console.error("Error attempting to enable fullscreen:", err);
        });
      }
    }
  };

  const seek = (seconds: number) => {
    if (videoRef.current) {
      videoRef.current.currentTime += seconds;
    }
  };

  const handleOpenChange = (open: boolean) => {
    if (!open) {
      onClose();
      setVideoError(false);
    }
  };

  const handlePopOut = () => {
    window.open('https://www.youtube.com/@ApnaCollegeOfficial', '_blank');
  };

  if (!currentVideo || videoFiles.length === 0) return null;

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent className="glass border-white/10 p-0 max-w-7xl h-[95vh] md:h-[90vh] flex flex-col overflow-hidden bg-black/95">
        <DialogHeader className="p-3 border-b border-white/10 flex flex-row items-center justify-between shrink-0 bg-black/40 backdrop-blur-md">
          <div className="flex items-center gap-2 flex-1 min-w-0">
            <Button
              variant="ghost"
              size="icon"
              onClick={playPrevious}
              disabled={currentVideoIndex === 0}
              className="text-white hover:bg-white/10 shrink-0"
            >
              <SkipBack className="w-5 h-5" />
            </Button>

            <Button
              variant="ghost"
              size="icon"
              onClick={playNext}
              disabled={currentVideoIndex === videoFiles.length - 1}
              className="text-white hover:bg-white/10 shrink-0"
            >
              <SkipForward className="w-5 h-5" />
            </Button>

            <DialogTitle className="text-white font-medium truncate ml-2 text-sm sm:text-base" data-testid="text-playlist-title">
              {currentVideo.name}
            </DialogTitle>
          </div>

          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => seek(-10)}
              className="text-white/70 hover:text-white hover:bg-white/10 hidden sm:flex"
              title="Rewind 10s"
            >
              <RotateCcw className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => seek(10)}
              className="text-white/70 hover:text-white hover:bg-white/10 hidden sm:flex"
              title="Forward 10s"
            >
              <RotateCw className="w-4 h-4" />
            </Button>

            <Button
              variant="ghost"
              size="icon"
              onClick={toggleFullscreen}
              className="text-white/70 hover:text-white hover:bg-white/10"
              title="Fullscreen"
            >
              <Maximize className="w-4 h-4" />
            </Button>

            <Button
              variant="ghost"
              size="icon"
              onClick={() => setShowPlaylist(!showPlaylist)}
              className={`text-white/70 hover:text-white hover:bg-white/10 ${showPlaylist ? 'bg-white/10' : ''}`}
            >
              <List className="w-4 h-4" />
            </Button>
          </div>
        </DialogHeader>

        <div className="flex flex-1 min-h-0 relative">
          {/* Video Player Area */}
          <div className={`flex-1 flex flex-col bg-black relative transition-all duration-300`}>
            <div className="flex-1 relative w-full h-full flex items-center justify-center">
              {videoError ? (
                <div className="text-center text-white px-4">
                  <p className="mb-2 text-lg font-semibold">Playback Error</p>
                  <Button onClick={retryVideo} variant="outline" className="border-white/20 text-white bg-transparent hover:bg-white/10 mt-4">
                    <RefreshCw className="w-4 h-4 mr-2" /> Retry
                  </Button>
                </div>
              ) : isRetrying ? (
                <div className="text-center text-white">
                  <RefreshCw className="w-10 h-10 animate-spin mx-auto mb-4 text-primary" />
                  <p className="text-lg font-medium">Reconnecting...</p>
                </div>
              ) : (
                <>
                  {urlAttempt < 2 ? (
                    <video
                      ref={videoRef}
                      controls
                      playsInline
                      className="w-full h-full max-h-full object-contain"
                      onError={handleVideoError}
                      onLoadedData={handleVideoLoad}
                      onCanPlay={handleVideoLoad}
                      onEnded={() => {
                        if (currentVideoIndex < videoFiles.length - 1) {
                          setTimeout(() => playNext(), 1000);
                        }
                      }}
                      autoPlay={true}
                    >
                      <source src={currentVideoUrl} type="video/mp4" />
                      Your browser does not support the video tag.
                    </video>
                  ) : (
                    <iframe
                      src={currentVideoUrl}
                      className="w-full h-full border-0"
                      onError={handleVideoError}
                      onLoad={handleVideoLoad}
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowFullScreen
                    />
                  )}
                </>
              )}
            </div>
            {/* Custom bottom controls removed to rely on native controls for better mobile compatibility */}
          </div>

          {/* Playlist Sidebar */}
          <div
            className={`
              absolute md:relative inset-0 md:inset-auto z-40 md:z-auto
              w-full md:w-80 bg-black/95 md:bg-black/50 backdrop-blur-xl border-l border-white/10
              transition-all duration-300 ease-in-out transform
              ${showPlaylist ? 'translate-x-0' : 'translate-x-full md:hidden'}
            `}
          >
            {/* Playlist content remains the same */}
            <div className="flex flex-col h-full">
              <div className="p-4 border-b border-white/10 flex items-center justify-between shrink-0">
                <div>
                  <h3 className="font-semibold text-white">Up Next</h3>
                  <p className="text-xs text-white/50">{videoFiles.length - currentVideoIndex - 1} videos remaining</p>
                </div>
                <Button variant="ghost" size="icon" onClick={() => setShowPlaylist(false)} className="md:hidden text-white">
                  <X className="w-5 h-5" />
                </Button>
              </div>

              <ScrollArea className="flex-1">
                <div className="p-3 space-y-2">
                  {videoFiles.map((video, index) => (
                    <div
                      key={video.id}
                      onClick={() => {
                        selectVideo(index);
                        if (window.innerWidth < 768) setShowPlaylist(false);
                      }}
                      className={`
                        group flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-all border border-transparent
                        ${index === currentVideoIndex
                          ? 'bg-primary/20 border-primary/30'
                          : 'hover:bg-white/5 hover:border-white/5'}
                      `}
                    >
                      <div className={`
                         w-10 h-10 rounded-lg flex items-center justify-center shrink-0 font-mono text-sm font-bold
                         ${index === currentVideoIndex ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'bg-white/5 text-white/40'}
                      `}>
                        {index + 1}
                      </div>
                      <div className="min-w-0 flex-1">
                        <h4 className={`text-sm font-medium truncate ${index === currentVideoIndex ? 'text-primary' : 'text-white/90'}`}>
                          {video.name}
                        </h4>
                      </div>
                    </div>
                  ))}
                </div>
              </ScrollArea>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}