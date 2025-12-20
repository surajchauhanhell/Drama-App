import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchGoogleDriveFiles, fetchFolderInfo, getFileType } from '@/services/google-drive';
import { DriveFile, FolderBreadcrumb } from '@/types/drive-types';
import FileCard from './file-card';
import FolderBreadcrumbComponent from './folder-breadcrumb';
import VideoPlaylist from './video-playlist';
import PDFModal from './pdf-modal';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { RefreshCw, FolderOpen, AlertTriangle, ArrowUpDown, Search, Grid, List as ListIcon } from 'lucide-react';

type SortField = 'name' | 'size' | 'type';
type SortOrder = 'asc' | 'desc';

export default function FileGrid() {
  const [currentFolderId, setCurrentFolderId] = useState<string | null>(null);
  const [breadcrumbs, setBreadcrumbs] = useState<FolderBreadcrumb[]>([]);
  const [selectedVideoId, setSelectedVideoId] = useState<string | null>(null);
  const [selectedPDF, setSelectedPDF] = useState<DriveFile | null>(null);
  const [isVideoPlaylistOpen, setIsVideoPlaylistOpen] = useState(false);
  const [isPDFModalOpen, setIsPDFModalOpen] = useState(false);
  const [sortField, setSortField] = useState<SortField>('name');
  const [sortOrder, setSortOrder] = useState<SortOrder>('asc');
  const [searchQuery, setSearchQuery] = useState('');

  const {
    data: files = [],
    isLoading,
    isError,
    error,
    refetch
  } = useQuery({
    queryKey: ['/api/google-drive-files', currentFolderId],
    queryFn: () => fetchGoogleDriveFiles(currentFolderId || undefined),
    staleTime: 5 * 60 * 1000, // 5 minutes
    retry: 2,
  });

  const handleOpenFolder = async (file: DriveFile) => {
    if (getFileType(file.mimeType) === 'folder') {
      // Add current folder to breadcrumbs
      const newBreadcrumbs = [...breadcrumbs, { id: file.id, name: file.name }];
      setBreadcrumbs(newBreadcrumbs);
      setCurrentFolderId(file.id);
      setSearchQuery(''); // Clear search when navigating
    } else {
      // For non-folders, open in Google Drive as fallback
      if (file.webViewLink) {
        window.open(file.webViewLink, '_blank');
      }
    }
  };

  const handleBreadcrumbNavigate = (folderId: string | null) => {
    if (folderId === null) {
      // Navigate to root
      setBreadcrumbs([]);
      setCurrentFolderId(null);
    } else {
      // Navigate to specific folder in breadcrumb
      const crumbIndex = breadcrumbs.findIndex(crumb => crumb.id === folderId);
      if (crumbIndex !== -1) {
        setBreadcrumbs(breadcrumbs.slice(0, crumbIndex + 1));
        setCurrentFolderId(folderId);
      }
    }
    setSearchQuery(''); // Clear search when navigating
  };

  const handleOpenVideo = (file: DriveFile) => {
    setSelectedVideoId(file.id);
    setIsVideoPlaylistOpen(true);
  };

  const handleOpenPDF = (file: DriveFile) => {
    setSelectedPDF(file);
    setIsPDFModalOpen(true);
  };

  const handleOpenImage = (file: DriveFile) => {
    // For images, we'll open them in a new tab for now
    if (file.webViewLink) {
      window.open(file.webViewLink, '_blank');
    }
  };

  const handleRefresh = () => {
    refetch();
  };

  const sortFiles = (files: DriveFile[]): DriveFile[] => {
    return [...files].sort((a, b) => {
      // Always put folders first
      const aIsFolder = getFileType(a.mimeType) === 'folder';
      const bIsFolder = getFileType(b.mimeType) === 'folder';

      if (aIsFolder && !bIsFolder) return -1;
      if (!aIsFolder && bIsFolder) return 1;

      let aValue: string | number;
      let bValue: string | number;

      switch (sortField) {
        case 'name':
          // Enhanced numeric sorting for names with numbers
          const aName = a.name.toLowerCase();
          const bName = b.name.toLowerCase();

          // Check if both names contain numbers
          const aMatch = aName.match(/(\d+)/);
          const bMatch = bName.match(/(\d+)/);

          if (aMatch && bMatch) {
            // Extract the numeric parts
            const aNum = parseInt(aMatch[0]);
            const bNum = parseInt(bMatch[0]);

            // If numbers are different, sort by number
            if (aNum !== bNum) {
              aValue = aNum;
              bValue = bNum;
            } else {
              // If numbers are same, sort alphabetically
              aValue = aName;
              bValue = bName;
            }
          } else {
            // Fallback to alphabetical sorting
            aValue = aName;
            bValue = bName;
          }
          break;
        case 'size':
          aValue = parseInt(a.size || '0');
          bValue = parseInt(b.size || '0');
          break;
        case 'type':
          aValue = getFileType(a.mimeType);
          bValue = getFileType(b.mimeType);
          break;
        default:
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
      }

      if (sortOrder === 'asc') {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0;
      }
    });
  };

  const filteredFiles = files.filter(file =>
    file.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const sortedFiles = sortFiles(filteredFiles);

  if (isLoading) {
    return (
      <div className="space-y-8">
        <div className="flex flex-col items-center justify-center py-20 gap-4">
          <div className="w-12 h-12 rounded-full border-4 border-primary/30 border-t-primary animate-spin" />
          <div className="text-lg font-medium text-white/80">Loading content...</div>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center px-4">
        <div className="w-20 h-20 rounded-2xl bg-red-500/10 flex items-center justify-center mb-6">
          <AlertTriangle className="w-10 h-10 text-red-400" />
        </div>
        <h3 className="text-2xl font-bold mb-2 text-white">Connection Error</h3>
        <p className="mb-8 text-white/50 max-w-md">
          {error instanceof Error ? error.message : 'Unable to connect to Google Drive. Please check your internet connection.'}
        </p>
        <Button onClick={handleRefresh} data-testid="button-retry" className="bg-white text-black hover:bg-white/90">
          <RefreshCw className="w-4 h-4 mr-2" />
          Try Again
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6 fade-in">
      {/* Controls Bar */}
      <div className="glass rounded-2xl p-4 flex flex-col md:flex-row gap-4 items-center justify-between sticky top-28 z-30">
        <div className="w-full md:w-auto flex-1">
          {/* Breadcrumb Navigation integrated */}
          {breadcrumbs.length > 0 ? (
            <FolderBreadcrumbComponent
              breadcrumbs={breadcrumbs}
              onNavigate={handleBreadcrumbNavigate}
            />
          ) : (
            <div className="flex items-center gap-2 text-white/80 font-medium">
              <FolderOpen className="w-5 h-5 text-primary" />
              <span>Root Directory</span>
            </div>
          )}
        </div>

        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
          {/* Search bar */}
          <div className="relative w-full sm:w-64">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-white/40 w-4 h-4" />
            <Input
              placeholder="Filter files..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="glass-input pl-10 h-10 w-full rounded-lg text-sm border-white/5 focus:border-white/20"
              data-testid="input-search"
            />
          </div>

          <div className="flex items-center gap-2">
            <Select value={sortField} onValueChange={(value: SortField) => setSortField(value)}>
              <SelectTrigger className="glass-input w-[110px] h-10 border-white/5" data-testid="select-sort-field">
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="bg-black/90 border-white/10 text-white backdrop-blur-xl">
                <SelectItem value="name">Name</SelectItem>
                <SelectItem value="size">Size</SelectItem>
                <SelectItem value="type">Type</SelectItem>
              </SelectContent>
            </Select>

            <Button
              variant="outline"
              size="icon"
              onClick={() => setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}
              className="glass-input w-10 h-10 border-white/5 hover:bg-white/10 hover:text-white"
              data-testid="button-toggle-sort-order"
            >
              <ArrowUpDown className="w-4 h-4" />
            </Button>

            <Button
              variant="outline"
              size="icon"
              onClick={handleRefresh}
              className="glass-input w-10 h-10 border-white/5 hover:bg-white/10 hover:text-white"
              data-testid="button-refresh"
            >
              <RefreshCw className="w-4 h-4" />
            </Button>
          </div>
        </div>
      </div>

      {sortedFiles.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-32 text-center">
          <div className="w-24 h-24 rounded-full bg-white/5 flex items-center justify-center mb-6">
            <FolderOpen className="w-10 h-10 text-white/20" />
          </div>
          <h3 className="text-xl font-bold mb-2 text-white">No files found</h3>
          <p className="mb-6 text-white/40">The current directory is empty.</p>
          {breadcrumbs.length > 0 && (
            <Button onClick={() => handleBreadcrumbNavigate(null)} variant="outline" className="border-white/10 text-white hover:bg-white/5">
              Return to Root
            </Button>
          )}
        </div>
      ) : (
        <>
          <div className="flex items-center justify-between px-2">
            <span className="text-sm text-white/40 font-medium">
              Showing {sortedFiles.length} item{sortedFiles.length !== 1 ? 's' : ''}
            </span>
          </div>

          {/* Files grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 pb-20">
            {sortedFiles.map((file) => (
              <div key={file.id} className="fade-in">
                <FileCard
                  file={file}
                  onOpenVideo={handleOpenVideo}
                  onOpenPDF={handleOpenPDF}
                  onOpenImage={handleOpenImage}
                  onOpenFolder={handleOpenFolder}
                />
              </div>
            ))}
          </div>
        </>
      )}

      {/* Modals */}
      <VideoPlaylist
        files={files.filter(file => getFileType(file.mimeType) === 'video')}
        initialVideoId={selectedVideoId || undefined}
        isOpen={isVideoPlaylistOpen}
        onClose={() => {
          setIsVideoPlaylistOpen(false);
          setSelectedVideoId(null);
        }}
      />

      <PDFModal
        file={selectedPDF}
        isOpen={isPDFModalOpen}
        onClose={() => {
          setIsPDFModalOpen(false);
          setSelectedPDF(null);
        }}
      />
    </div>
  );
}
