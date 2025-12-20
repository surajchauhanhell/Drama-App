import { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Lock, ArrowRight, ShieldCheck } from 'lucide-react';

interface PasswordScreenProps {
  onAuthenticated: () => void;
  accessCode: string;
}

export default function PasswordScreen({ onAuthenticated, accessCode: correctAccessCode }: PasswordScreenProps) {
  const [inputCode, setInputCode] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    // Simulate a brief loading time for better UX
    await new Promise(resolve => setTimeout(resolve, 500));

    if (inputCode === correctAccessCode) {
      onAuthenticated();
    } else {
      setError('Invalid access code. Please try again.');
      setInputCode('');
      setTimeout(() => setError(''), 3000);
    }

    setIsLoading(false);
  };

  return (
    <div className="min-h-screen w-full flex items-center justify-center p-4 gradient-bg relative overflow-hidden">
      {/* Abstract Background Shapes */}
      <div className="absolute top-[-20%] right-[-10%] w-[50%] h-[50%] bg-primary/20 blur-[120px] rounded-full animate-pulse" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[40%] h-[40%] bg-accent/20 blur-[100px] rounded-full animate-pulse delay-75" />

      <Card className="glass-card w-full max-w-md border-0 relative z-10 scale-in">
        <CardContent className="pt-10 pb-10 px-8">
          <div className="text-center mb-10 slide-up" style={{ animationDelay: '0.1s' }}>
            <div className="flex justify-center mb-6">
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-primary to-accent p-[2px] shadow-2xl shadow-primary/20">
                <div className="w-full h-full rounded-2xl bg-black/50 backdrop-blur-xl flex items-center justify-center">
                  <ShieldCheck className="w-10 h-10 text-white" />
                </div>
              </div>
            </div>
            <h1 className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-white to-white/70 tracking-tight mb-2">
              Drama
            </h1>
            <p className="text-muted-foreground">Enter access code to continue</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6 slide-up" style={{ animationDelay: '0.2s' }}>
            <div className="space-y-2 group">
              <Label htmlFor="access-code" className="text-sm font-medium ml-1 text-white/80 group-focus-within:text-primary transition-colors">
                Access Code
              </Label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 transform -translate-y-1/2 text-white/40 w-5 h-5 group-focus-within:text-primary transition-colors" />
                <Input
                  id="access-code"
                  type="password"
                  value={inputCode}
                  onChange={(e) => setInputCode(e.target.value)}
                  placeholder="Enter access code"
                  className="glass-input h-14 pl-12 rounded-xl text-base"
                  data-testid="input-access-code"
                  disabled={isLoading}
                />
              </div>
            </div>

            <Button
              type="submit"
              className="w-full h-14 rounded-xl text-base font-bold bg-gradient-to-r from-primary to-accent hover:opacity-90 transition-all shadow-lg shadow-primary/25 mt-2"
              disabled={isLoading}
              data-testid="button-submit-password"
            >
              {isLoading ? (
                <span className="flex items-center gap-2">Verifying...</span>
              ) : (
                <span className="flex items-center gap-2">Access Files <ArrowRight className="w-5 h-5" /></span>
              )}
            </Button>

            {error && (
              <div className="text-red-400 text-sm text-center bg-red-500/10 border border-red-500/20 p-4 rounded-xl fade-in">
                {error}
              </div>
            )}
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
