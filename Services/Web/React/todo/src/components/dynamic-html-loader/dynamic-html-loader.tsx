import { useEffect, useState } from 'react';

type DynamicHtmlLoaderProps = {
  filePath: string;
};

export default function DynamicHtmlLoader({ filePath }: DynamicHtmlLoaderProps) {
  const [htmlContent, setHtmlContent] = useState('');
    
  useEffect(() => {
    if (!filePath) return;
    fetch(filePath)
      .then(res => res.text())
      .then(html => setHtmlContent(html));
  }, [filePath]);

  return (
    <div dangerouslySetInnerHTML={{ __html: htmlContent }} />
  );
}