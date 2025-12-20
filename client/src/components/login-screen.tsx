import { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { loginWithEmail } from '@/lib/firebase';
import { User, Mail, Lock, ArrowRight } from 'lucide-react';

interface LoginScreenProps {
  onAuthenticated: () => void;
}

export default function LoginScreen({ onAuthenticated }: LoginScreenProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      await loginWithEmail(email, password);
      onAuthenticated();
    } catch (error: any) {
      setError(error.message || 'Login failed. Please check your credentials.');
      setEmail('');
      setPassword('');
      setTimeout(() => setError(''), 5000);
    }

    setIsLoading(false);
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center p-4 gradient-bg relative overflow-hidden">
      {/* Abstract Background Shapes */}
      <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-primary/20 blur-[120px] rounded-full animate-pulse" />
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-accent/20 blur-[100px] rounded-full animate-pulse delay-75" />

      <Card className="glass-card w-full max-w-md border-0 relative z-10 scale-in">
        <CardContent className="pt-10 pb-10 px-8">
          <div className="text-center mb-10 slide-up" style={{ animationDelay: '0.1s' }}>
            <div className="flex justify-center mb-6">
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary to-accent p-[2px] shadow-2xl shadow-primary/20">
                <div className="w-full h-full rounded-2xl bg-black/50 backdrop-blur-xl flex items-center justify-center">
                  <User className="w-10 h-10 text-white" />
                </div>
              </div>
            </div>
            <h1 className="text-5xl font-black text-transparent bg-clip-text bg-gradient-to-r from-white to-white/70 tracking-tight mb-3">
              Drama
            </h1>
            <p className="text-muted-foreground text-lg">Your premium media vault</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6 slide-up" style={{ animationDelay: '0.2s' }}>
            <div className="space-y-2 group">
              <Label htmlFor="email" className="text-sm font-medium ml-1 text-white/80 group-focus-within:text-primary transition-colors">
                Email Address
              </Label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 transform -translate-y-1/2 text-white/40 w-5 h-5 group-focus-within:text-primary transition-colors" />
                <Input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your email"
                  className="glass-input h-14 pl-12 rounded-xl text-base"
                  data-testid="input-email"
                  disabled={isLoading}
                  required
                />
              </div>
            </div>

            <div className="space-y-2 group">
              <Label htmlFor="password" className="text-sm font-medium ml-1 text-white/80 group-focus-within:text-primary transition-colors">
                Password
              </Label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-white/40 w-5 h-5 group-focus-within:text-primary transition-colors" />
                <Input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  className="glass-input h-14 pl-12 rounded-xl text-base"
                  data-testid="input-password"
                  disabled={isLoading}
                  required
                />
              </div>
            </div>

            <Button
              type="submit"
              className="w-full h-14 rounded-xl text-base font-bold bg-gradient-to-r from-primary to-accent hover:opacity-90 transition-all shadow-lg shadow-primary/25 mt-2"
              disabled={isLoading || !email || !password}
              data-testid="button-login"
            >
              {isLoading ? (
                <span className="flex items-center gap-2">Processing...</span>
              ) : (
                <span className="flex items-center gap-2">Sign In <ArrowRight className="w-5 h-5" /></span>
              )}
            </Button>

            {error && (
              <div className="text-red-400 text-sm text-center bg-red-500/10 border border-red-500/20 p-4 rounded-xl fade-in">
                {error}
              </div>
            )}
          </form>

          <div className="mt-8 text-center slide-up" style={{ animationDelay: '0.3s' }}>
            <p className="text-xs text-white/30 uppercase tracking-widest font-mono">
              Restricted Access
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}