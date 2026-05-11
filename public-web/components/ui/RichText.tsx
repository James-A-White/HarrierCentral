"use client";

import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeRaw from "rehype-raw";

interface RichTextProps {
  content: string;
  color?: string;
  align?: "left" | "center" | "right";
}

/**
 * Renders markdown with kennel-themed styling.
 * Used by both ContentBlock (body) and RichTextBlock.
 */
export function RichText({ content, color, align = "left" }: RichTextProps) {
  if (!content?.trim()) return null;

  const textColor   = color || "var(--kennel-text-body)";
  const headingColor = color || "var(--kennel-text-title)";
  const textAlign   = align;

  return (
    <div className="min-w-0 w-full" style={{ color: textColor, textAlign }}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeRaw]}
        components={{
          h1: ({ children }) => (
            <h1 className="text-4xl font-black mt-8 mb-3 first:mt-0" style={{ color: headingColor }}>
              {children}
            </h1>
          ),
          h2: ({ children }) => (
            <h2 className="text-3xl font-bold mt-7 mb-3 first:mt-0" style={{ color: headingColor }}>
              {children}
            </h2>
          ),
          h3: ({ children }) => (
            <h3 className="text-2xl font-bold mt-6 mb-2 first:mt-0" style={{ color: headingColor }}>
              {children}
            </h3>
          ),
          h4: ({ children }) => (
            <h4 className="text-xl font-semibold mt-5 mb-2 first:mt-0" style={{ color: headingColor }}>
              {children}
            </h4>
          ),
          p: ({ children }) => (
            <p className="text-lg leading-relaxed mb-4 last:mb-0">
              {children}
            </p>
          ),
          a: ({ href, children }) => (
            <a
              href={href}
              className="font-medium underline underline-offset-2 transition-opacity hover:opacity-70"
              style={{ color: "var(--kennel-primary)" }}
              target={href?.startsWith("http") ? "_blank" : undefined}
              rel={href?.startsWith("http") ? "noopener noreferrer" : undefined}
            >
              {children}
            </a>
          ),
          ul: ({ children }) => (
            <ul className="list-disc list-outside pl-6 mb-4 last:mb-0 space-y-1.5 text-lg">
              {children}
            </ul>
          ),
          ol: ({ children }) => (
            <ol className="list-decimal list-outside pl-6 mb-4 last:mb-0 space-y-1.5 text-lg">
              {children}
            </ol>
          ),
          li: ({ children }) => (
            <li className="leading-relaxed">{children}</li>
          ),
          strong: ({ children }) => (
            <strong className="font-semibold" style={{ color: headingColor }}>
              {children}
            </strong>
          ),
          em: ({ children }) => (
            <em className="italic">{children}</em>
          ),
          hr: () => (
            <hr className="my-6 border-0 border-t" style={{ borderColor: "color-mix(in srgb, var(--kennel-text-muted) 30%, transparent)" }} />
          ),
          blockquote: ({ children }) => (
            <blockquote
              className="border-l-4 pl-4 my-4 italic text-lg"
              style={{ borderColor: "var(--kennel-primary)", color: "var(--kennel-text-muted)" }}
            >
              {children}
            </blockquote>
          ),
        }}
      >
        {content}
      </ReactMarkdown>
    </div>
  );
}
