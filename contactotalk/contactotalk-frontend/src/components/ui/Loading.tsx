interface LoadingProps {
  size?: 'sm' | 'md' | 'lg';
  text?: string;
  fullScreen?: boolean;
}

export default function Loading({
  size = 'md',
  text = '로딩 중...',
  fullScreen = false
}: LoadingProps) {
  const sizeClasses = {
    sm: 'h-8 w-8 border-2',
    md: 'h-12 w-12 border-b-2',
    lg: 'h-16 w-16 border-b-3',
  };

  const containerClasses = fullScreen
    ? 'min-h-screen flex items-center justify-center bg-gray-50'
    : 'flex items-center justify-center py-8';

  return (
    <div className={containerClasses}>
      <div className="text-center">
        <div
          className={`animate-spin rounded-full border-blue-600 mx-auto ${sizeClasses[size]}`}
        />
        {text && <p className="mt-4 text-gray-600">{text}</p>}
      </div>
    </div>
  );
}
