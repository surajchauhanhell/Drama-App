import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { DriveFile } from '@/types/drive-types';
import { getPDFUrl } from '@/services/google-drive';
import { Download, ExternalLink, FileText } from 'lucide-react';

interface PDFModalProps {
  file: DriveFile | null;
  isOpen: boolean;
  onClose: () => void;
}

export default function PDFModal({ file, isOpen, onClose }: PDFModalProps) {
  const [pdfError, setPdfError] = useState(false);

  const handlePDFError = () => {
    setPdfError(true);
  };

  const handleOpenChange = (open: boolean) => {
    if (!open) {
      onClose();
      setPdfError(false);
    }
  };

  const handleDownload = () => {
    if (file?.webContentLink) {
      const link = document.createElement('a');
      link.href = file.webContentLink;
      link.download = file.name;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  };

  const handlePopOut = () => {
    window.open('https://www.youtube.com/@ApnaCollegeOfficial', '_blank');
  };

  if (!file) return null;

  const pdfSrc = getPDFUrl(file.id);

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent className="glass border-white/10 p-0 max-w-6xl h-[95vh] flex flex-col bg-black/90">
        <DialogHeader className="p-4 border-b border-white/10 flex flex-row items-center justify-between shrink-0 bg-white/5">
          <div className="flex items-center gap-3 overflow-hidden">
            <div className="w-8 h-8 rounded-lg bg-red-500/10 flex items-center justify-center shrink-0">
              <FileText className="w-4 h-4 text-red-400" />
            </div>
            <DialogTitle className="text-white truncate" data-testid="text-pdf-title">
              {file.name}
            </DialogTitle>
          </div>

          <div className="flex items-center gap-2 shrink-0 ml-4">
            <Button
              variant="ghost"
              size="sm"
              onClick={handlePopOut}
              className="text-white/70 hover:text-white hover:bg-white/10"
              data-testid="button-popout-pdf"
              title="Visit Apna College YouTube Channel"
            >
              <ExternalLink className="w-4 h-4" />
            </Button>
            <Button
              variant="default"
              size="sm"
              onClick={handleDownload}
              className="bg-primary hover:bg-primary/90 text-white shadow-lg shadow-primary/20"
              data-testid="button-download-pdf"
            >
              <Download className="w-4 h-4 mr-2" />
              <span className="hidden sm:inline">Download</span>
            </Button>
          </div>
        </DialogHeader>

        <div className="flex-1 min-h-0 bg-white/5 relative">
          {pdfError ? (
            <div className="flex items-center justify-center h-full">
              <div className="text-center p-8 bg-black/40 rounded-2xl border border-white/10 backdrop-blur-xl">
                <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mx-auto mb-4">
                  <FileText className="w-8 h-8 text-white/20" />
                </div>
                <p className="mb-2 text-white font-medium">Unable to preview PDF</p>
                <p className="text-sm text-white/50 mb-6 max-w-xs">
                  The viewer encountered an error. Please download the file to view it.
                </p>
                <Button onClick={handleDownload} variant="outline" className="border-white/20 text-white hover:bg-white/10">
                  <Download className="w-4 h-4 mr-2" />
                  Download File
                </Button>
              </div>
            </div>
          ) : (
            <iframe
              src={pdfSrc}
              className="w-full h-full pdf-viewer border-0"
              onError={handlePDFError}
              data-testid="pdf-viewer"
              title={`PDF viewer for ${file.name}`}
            />
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
