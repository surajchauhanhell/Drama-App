import { Button } from '@/components/ui/button';
import { FolderBreadcrumb } from '@/types/drive-types';
import { ChevronRight, Home } from 'lucide-react';

interface FolderBreadcrumbProps {
  breadcrumbs: FolderBreadcrumb[];
  onNavigate: (folderId: string | null) => void;
}

export default function FolderBreadcrumbComponent({ breadcrumbs, onNavigate }: FolderBreadcrumbProps) {
  return (
    <div className="flex items-center gap-1 text-sm text-muted-foreground mb-6">
      <Button
        variant="ghost"
        size="sm"
        onClick={() => onNavigate(null)}
        className="h-8 px-2 text-muted-foreground hover:text-foreground"
        data-testid="breadcrumb-home"
      >
        <Home className="w-4 h-4 mr-1" />
        Home
      </Button>
      
      {breadcrumbs.map((crumb, index) => (
        <div key={crumb.id} className="flex items-center gap-1">
          <ChevronRight className="w-4 h-4" />
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onNavigate(crumb.id)}
            className="h-8 px-2 text-muted-foreground hover:text-foreground"
            data-testid={`breadcrumb-${crumb.id}`}
          >
            {crumb.name}
          </Button>
        </div>
      ))}
    </div>
  );
}