import type { Metadata, Viewport } from "next";
import "./globals.css";
import ErrorBoundary from "@/components/error/ErrorBoundary";
import AuthProvider from "@/components/providers/AuthProvider";

export const metadata: Metadata = {
  title: {
    default: "ConTacToTalk - 글로벌 매칭 & 채팅 플랫폼",
    template: "%s | ConTacToTalk",
  },
  description: "전 세계 사람들과 소통하는 매칭 기반 채팅 플랫폼. 관심사 기반 1:1 매칭, 오픈 채팅, SNS 기능을 통해 새로운 친구를 만나보세요.",
  keywords: ["채팅", "매칭", "글로벌", "친구", "SNS", "언어교환", "소셜"],
  authors: [{ name: "ConTacToTalk" }],
  creator: "ConTacToTalk",
  openGraph: {
    type: "website",
    locale: "ko_KR",
    url: "https://contactotalk.com",
    title: "ConTacToTalk - 글로벌 매칭 & 채팅 플랫폼",
    description: "전 세계 사람들과 소통하는 매칭 기반 채팅 플랫폼",
    siteName: "ConTacToTalk",
  },
  twitter: {
    card: "summary_large_image",
    title: "ConTacToTalk - 글로벌 매칭 & 채팅 플랫폼",
    description: "전 세계 사람들과 소통하는 매칭 기반 채팅 플랫폼",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: "#2563eb",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <head>
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="default" />
        <link rel="manifest" href="/manifest.json" />
      </head>
      <body className="antialiased">
        <AuthProvider>
          <ErrorBoundary>{children}</ErrorBoundary>
        </AuthProvider>
      </body>
    </html>
  );
}
