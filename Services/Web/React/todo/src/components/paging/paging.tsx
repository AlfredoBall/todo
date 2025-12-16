import './paging.css';

interface PagingProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

export function Paging({
  currentPage,
  totalPages,
  onPageChange }: PagingProps) {

  const goToPage = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      onPageChange(page);
    }
  }

  const previousPage = () => {
    if (currentPage > 1) {
      onPageChange(currentPage - 1);
    }
  }

  const nextPage = () => {
    if (currentPage < totalPages) {
      onPageChange(currentPage + 1);
    }
  }

  const getPageNumbers = (): number[] => {
    const pages: number[] = [];

    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) {
        pages.push(i);
      }
    } else {
      if (currentPage <= 4) {
        for (let i = 1; i <= 5; i++) pages.push(i);
        pages.push(-1);
        pages.push(totalPages);
      } else if (currentPage >= totalPages - 3) {
        pages.push(1);
        pages.push(-1);
        for (let i = totalPages - 4; i <= totalPages; i++) pages.push(i);
      } else {
        pages.push(1);
        pages.push(-1);
        for (let i = currentPage - 1; i <= currentPage + 1; i++) pages.push(i);
        pages.push(-1);
        pages.push(totalPages);
      }
    }

    return pages;
  }

  return (
    <div className="paging-container">
      {totalPages > 1 && (
        <>
          <button 
            className="page-button nav-button" 
            onClick={previousPage} 
            disabled={currentPage === 1}>
            Previous
          </button>

          {getPageNumbers().map((page, index) => (
            page === -1 ? (
              <span key={`ellipsis-${index}`} className="ellipsis">...</span>
            ) : (
              <button 
                key={page}
                className={`page-button ${page === currentPage ? 'active' : ''}`}
                onClick={() => goToPage(page)}>
                {page}
              </button>
            )
          ))}

          <button 
            className="page-button nav-button" 
            onClick={nextPage} 
            disabled={currentPage === totalPages}>
            Next
          </button>
        </>
      )}
    </div>
  );
}