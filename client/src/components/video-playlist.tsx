import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { ScrollArea } from '@/components/ui/scroll-area';
import { DriveFile } from '@/types/drive-types';
import { getVideoUrlEmbed } from '@/services/google-drive';
import {
  Play,
  Pause,
  SkipForward,
  SkipBack,
  Volume2,
  VolumeX,
  List,
  X,
  RefreshCw,
  ExternalLink,
  ChevronRight,
  ChevronLeft
} from 'lucide-react';

interface VideoPlaylistProps {
  files: DriveFile[];
  initialVideoId?: string;
  isOpen: boolean;
  onClose: () => void;
}

export default function VideoPlaylist({ files, initialVideoId, isOpen, onClose }: VideoPlaylistProps) {
  const videoFiles = files;
  const [currentVideoIndex, setCurrentVideoIndex] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
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
      // Start with the highest quality preview URL
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

  const togglePlay = () => {
    const video = document.querySelector('[data-testid="playlist-video-player"]') as HTMLVideoElement;
    if (video) {
      if (isPlaying) {
        video.pause();
        setIsPlaying(false);
      } else {
        const playPromise = video.play();
        if (playPromise !== undefined) {
          playPromise
            .then(() => setIsPlaying(true))
            .catch((error) => {
              console.log('Play was prevented:', error);
              setIsPlaying(false);
            });
        }
      }
    }
  };

  const toggleMute = () => {
    const video = document.querySelector('[data-testid="playlist-video-player"]') as HTMLVideoElement;
    if (video) {
      video.muted = !isMuted;
      setIsMuted(!isMuted);
    }
  };

  const handleOpenChange = (open: boolean) => {
    if (!open) {
      onClose();
      setIsPlaying(false);
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
        <DialogHeader className="p-4 border-b border-white/10 flex flex-row items-center justify-between shrink-0 bg-black/40 backdrop-blur-md">
          <DialogTitle className="flex-1 text-white font-medium truncate pr-4" data-testid="text-playlist-title">
            {currentVideo.name}
          </DialogTitle>
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={handlePopOut}
              className="text-white/70 hover:text-white hover:bg-white/10"
              data-testid="button-popout"
              title="Visit Apna College YouTube Channel"
            >
              <ExternalLink className="w-4 h-4" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowPlaylist(!showPlaylist)}
              className={`text-white/70 hover:text-white hover:bg-white/10 ${showPlaylist ? 'bg-white/10' : ''}`}
              data-testid="button-toggle-playlist"
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
                  <p className="text-sm text-white/50 mb-6 max-w-md mx-auto">
                    Unable to stream this video directly. It might be too large or restricted.
                  </p>
                  <div className="flex gap-3 justify-center">
                    <Button onClick={retryVideo} variant="outline" className="border-white/20 text-white bg-transparent hover:bg-white/10">
                      <RefreshCw className="w-4 h-4 mr-2" /> Retry
                    </Button>
                    <Button onClick={handlePopOut} className="bg-primary hover:bg-primary/90 text-white">
                      <ExternalLink className="w-4 h-4 mr-2" /> Open External
                    </Button>
                  </div>
                </div>
              ) : isRetrying ? (
                <div className="text-center text-white">
                  <RefreshCw className="w-10 h-10 animate-spin mx-auto mb-4 text-primary" />
                  <p className="text-lg font-medium">Loading Player...</p>
                </div>
              ) : (
                <>
                  {urlAttempt < 2 ? (
                    <video
                      controls
                      className="w-full h-full max-h-full object-contain"
                      onError={handleVideoError}
                      onLoadedData={handleVideoLoad}
                      onCanPlay={handleVideoLoad}
                      onPlay={() => setIsPlaying(true)}
                      onPause={() => setIsPlaying(false)}
                      onEnded={() => {
                        setIsPlaying(false);
                        if (currentVideoIndex < videoFiles.length - 1) {
                          setTimeout(() => playNext(), 1000);
                        }
                      }}
                      data-testid="playlist-video-player"
                      key={`${currentVideo.id}-${urlAttempt}`}
                      autoPlay={true}
                      poster="https://via.placeholder.com/1280x720/000000/FFFFFF?text=Loading+Video..."
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
                      data-testid="playlist-video-iframe"
                      key={`${currentVideo.id}-iframe`}
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                      allowFullScreen
                      sandbox="allow-scripts allow-same-origin allow-presentation"
                    />
                  )}

                  {/* Overlay for iframe interaction capture */}
                  {urlAttempt >= 2 && (
                    <div
                      className="absolute top-4 right-4 z-30 opacity-0 hover:opacity-100 transition-opacity"
                      data-testid="iframe-popout-overlay"
                    >
                      <Button onClick={handlePopOut} size="sm" className="bg-black/50 hover:bg-black/70 text-white backdrop-blur-md">
                        <ExternalLink className="w-4 h-4 mr-2" /> Open in YT
                      </Button>
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Custom Bottom Controls */}
            {!videoError && urlAttempt < 2 && (
              <div className="absolute bottom-6 left-1/2 transform -translate-x-1/2 z-20">
                <div className="flex items-center gap-1 bg-black/60 backdrop-blur-xl border border-white/10 rounded-full px-4 py-2 shadow-2xl">
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={playPrevious}
                    disabled={currentVideoIndex === 0}
                    className="text-white hover:bg-white/20 rounded-full w-8 h-8"
                  >
                    <SkipBack className="w-4 h-4" />
                  </Button>

                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={togglePlay}
                    className="text-white hover:bg-white/20 rounded-full w-10 h-10"
                  >
                    {isPlaying ? <Pause className="w-5 h-5 fill-current" /> : <Play className="w-5 h-5 fill-current ml-0.5" />}
                  </Button>

                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={playNext}
                    disabled={currentVideoIndex === videoFiles.length - 1}
                    className="text-white hover:bg-white/20 rounded-full w-8 h-8"
                  >
                    <SkipForward className="w-4 h-4" />
                  </Button>

                  <div className="w-px h-4 bg-white/20 mx-1" />

                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={toggleMute}
                    className="text-white hover:bg-white/20 rounded-full w-8 h-8"
                  >
                    {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
                  </Button>
                </div>
              </div>
            )}
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
                        // On mobile, auto-close playlist after selection for better UX
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
                        {index === currentVideoIndex && isPlaying ? (
                          <div className="flex gap-0.5 items-end h-3">
                            <span className="w-0.5 h-full bg-white animate-pulse" />
                            <span className="w-0.5 h-2/3 bg-white animate-pulse delay-75" />
                            <span className="w-0.5 h-1/2 bg-white animate-pulse delay-150" />
                          </div>
                        ) : (
                          index + 1
                        )}
                      </div>

                      <div className="min-w-0 flex-1">
                        <h4 className={`text-sm font-medium truncate ${index === currentVideoIndex ? 'text-primary' : 'text-white/90'}`}>
                          {video.name}
                        </h4>
                        <p className="text-xs text-white/40 mt-0.5">
                          {video.size ? `${Math.round(parseInt(video.size) / (1024 * 1024))}MB` : 'Unknown size'}
                        </p>
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