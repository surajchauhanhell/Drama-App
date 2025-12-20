import { useState, useEffect } from 'react';
import LoginScreen from '@/components/login-screen';
import FileGrid from '@/components/file-grid';
import { Button } from '@/components/ui/button';
import { LogOut, Menu } from 'lucide-react';
import { onAuthChange, logout } from '@/lib/firebase';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export default function Home() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [userEmail, setUserEmail] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = onAuthChange((user) => {
      setIsAuthenticated(!!user);
      setUserEmail(user?.email || null);
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleAuthenticated = () => {
    setIsAuthenticated(true);
  };

  const handleLogout = async () => {
    try {
      await logout();
      setIsAuthenticated(false);
      setUserEmail(null);
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center gradient-bg">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 rounded-full border-4 border-primary/30 border-t-primary animate-spin" />
          <div className="text-white/80 font-medium tracking-wide">INITIALIZING...</div>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginScreen onAuthenticated={handleAuthenticated} />;
  }

  return (
    <div className="min-h-screen gradient-bg flex flex-col">
      {/* Premium Glass Header */}
      <header className="sticky top-4 z-50 px-4 md:px-8">
        <div className="glass rounded-2xl max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex items-center justify-between h-20">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-lg shadow-primary/20">
                <span className="text-white font-black text-xl">D</span>
              </div>
              <h1 className="text-2xl font-black text-white tracking-tight hidden sm:block" data-testid="text-app-title">
                Drama
              </h1>
            </div>

            <div className="flex items-center gap-4">
              {userEmail && (
                <div className="hidden md:flex flex-col items-end mr-2">
                  <span className="text-xs text-white/50 uppercase tracking-wider font-bold">Logged in as</span>
                  <span className="text-sm text-white font-medium">
                    {userEmail}
                  </span>
                </div>
              )}

              <div className="hidden sm:block">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleLogout}
                  className="text-white/70 hover:text-white hover:bg-white/10 rounded-xl"
                  data-testid="button-logout"
                >
                  <LogOut className="w-4 h-4 mr-2" />
                  Sign Out
                </Button>
              </div>

              {/* Mobile Menu */}
              <div className="sm:hidden">
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon" className="text-white hover:bg-white/10 rounded-xl">
                      <Menu className="w-6 h-6" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="glass border-white/10 bg-black/90 text-white min-w-[200px]">
                    {userEmail && (
                      <div className="px-2 py-2 text-xs text-white/50 border-b border-white/10 mb-1">
                        {userEmail}
                      </div>
                    )}
                    <DropdownMenuItem onClick={handleLogout} className="text-red-400 focus:text-red-300 focus:bg-white/10 cursor-pointer">
                      <LogOut className="w-4 h-4 mr-2" />
                      Sign Out
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="flex-1 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        <FileGrid />
      </main>
    </div>
  );
}
