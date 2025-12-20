import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent } from '@/components/ui/card';
import { Settings, Lock, Check, X } from 'lucide-react';

interface AdminSettingsProps {
  isOpen: boolean;
  onClose: () => void;
  currentAccessCode: string;
  onAccessCodeChange: (newCode: string) => void;
}

export default function AdminSettings({ 
  isOpen, 
  onClose, 
  currentAccessCode, 
  onAccessCodeChange 
}: AdminSettingsProps) {
  const [masterPassword, setMasterPassword] = useState('');
  const [newAccessCode, setNewAccessCode] = useState('');
  const [step, setStep] = useState<'password' | 'newcode' | 'success'>('password');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleMasterPasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    // Simulate loading time
    await new Promise(resolve => setTimeout(resolve, 500));

    if (masterPassword === 'Asurajchyl1') {
      setStep('newcode');
    } else {
      setError('Invalid master password. Access denied.');
      setTimeout(() => setError(''), 3000);
    }
    
    setIsLoading(false);
  };

  const handleAccessCodeChange = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    if (!newAccessCode.trim()) {
      setError('Please enter a new access code.');
      setIsLoading(false);
      return;
    }

    // Simulate loading time
    await new Promise(resolve => setTimeout(resolve, 500));

    onAccessCodeChange(newAccessCode);
    setStep('success');
    setIsLoading(false);
  };

  const handleClose = () => {
    setMasterPassword('');
    setNewAccessCode('');
    setStep('password');
    setError('');
    onClose();
  };

  const renderPasswordStep = () => (
    <form onSubmit={handleMasterPasswordSubmit} className="space-y-6">
      <div className="text-center mb-6">
        <Lock className="w-12 h-12 mx-auto text-primary mb-4" />
        <h3 className="text-lg font-semibold">Admin Access Required</h3>
        <p className="text-sm text-muted-foreground">
          Enter master password to change access code
        </p>
      </div>
      
      <div className="space-y-2">
        <Label htmlFor="master-password">Master Password</Label>
        <Input
          id="master-password"
          type="password"
          value={masterPassword}
          onChange={(e) => setMasterPassword(e.target.value)}
          placeholder="Enter master password"
          data-testid="input-master-password"
          disabled={isLoading}
        />
      </div>
      
      <Button 
        type="submit" 
        className="w-full"
        disabled={isLoading}
        data-testid="button-verify-master-password"
      >
        {isLoading ? 'Verifying...' : 'Verify Password'}
      </Button>
      
      {error && (
        <div className="text-red-500 text-sm text-center bg-red-50 dark:bg-red-950/20 p-3 rounded-lg">
          {error}
        </div>
      )}
    </form>
  );

  const renderNewCodeStep = () => (
    <form onSubmit={handleAccessCodeChange} className="space-y-6">
      <div className="text-center mb-6">
        <Settings className="w-12 h-12 mx-auto text-green-500 mb-4" />
        <h3 className="text-lg font-semibold">Change Access Code</h3>
        <p className="text-sm text-muted-foreground">
          Enter new access code for the website
        </p>
      </div>
      
      <Card className="bg-muted/30">
        <CardContent className="p-4">
          <div className="text-sm">
            <span className="text-muted-foreground">Current access code: </span>
            <span className="font-mono font-semibold">{currentAccessCode}</span>
          </div>
        </CardContent>
      </Card>
      
      <div className="space-y-2">
        <Label htmlFor="new-access-code">New Access Code</Label>
        <Input
          id="new-access-code"
          type="text"
          value={newAccessCode}
          onChange={(e) => setNewAccessCode(e.target.value)}
          placeholder="Enter new access code"
          data-testid="input-new-access-code"
          disabled={isLoading}
        />
      </div>
      
      <div className="flex gap-2">
        <Button 
          type="button" 
          variant="outline" 
          className="flex-1"
          onClick={() => setStep('password')}
          disabled={isLoading}
        >
          Back
        </Button>
        <Button 
          type="submit" 
          className="flex-1"
          disabled={isLoading}
          data-testid="button-update-access-code"
        >
          {isLoading ? 'Updating...' : 'Update Code'}
        </Button>
      </div>
      
      {error && (
        <div className="text-red-500 text-sm text-center bg-red-50 dark:bg-red-950/20 p-3 rounded-lg">
          {error}
        </div>
      )}
    </form>
  );

  const renderSuccessStep = () => (
    <div className="text-center space-y-6">
      <div className="mb-6">
        <Check className="w-16 h-16 mx-auto text-green-500 mb-4" />
        <h3 className="text-lg font-semibold text-green-600">Access Code Updated!</h3>
        <p className="text-sm text-muted-foreground">
          The access code has been successfully changed
        </p>
      </div>
      
      <Card className="bg-green-50 dark:bg-green-950/20 border-green-200 dark:border-green-800">
        <CardContent className="p-4">
          <div className="text-sm text-center">
            <span className="text-muted-foreground">New access code: </span>
            <span className="font-mono font-bold text-green-700 dark:text-green-400">
              {newAccessCode}
            </span>
          </div>
        </CardContent>
      </Card>
      
      <Button 
        onClick={handleClose}
        className="w-full"
        data-testid="button-close-settings"
      >
        Close Settings
      </Button>
    </div>
  );

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Settings className="w-5 h-5" />
            Admin Settings
          </DialogTitle>
        </DialogHeader>
        
        <div className="py-4">
          {step === 'password' && renderPasswordStep()}
          {step === 'newcode' && renderNewCodeStep()}
          {step === 'success' && renderSuccessStep()}
        </div>
      </DialogContent>
    </Dialog>
  );
}