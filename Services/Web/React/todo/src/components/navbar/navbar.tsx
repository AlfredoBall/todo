import './navbar.css';
import { NavLink, useSearchParams } from 'react-router-dom';
import Login from '../login/login';

function buildQueryString(clipboardParam: number | null, pageParam: number | null, itemFilterParam: string | null) {
  const params = new URLSearchParams();
  if (clipboardParam !== null && clipboardParam !== undefined) {
    params.set('clipboard', clipboardParam.toString());
  }
  if (pageParam !== null && pageParam !== undefined) {
    params.set('page', pageParam.toString());
  }
  if (itemFilterParam) {
    params.set('itemFilter', itemFilterParam);
  }

  if (params.toString() === '') {
    return '';
  }

  return `?${params.toString()}`;
}

function Navbar() {
  const [searchParams] = useSearchParams();
  const clipboardParam = searchParams.has('clipboard') ? Number(searchParams.get('clipboard')) : null;
  const pageParam = searchParams.has('page') ? Number(searchParams.get('page')) : null;
  const itemFilterParam = searchParams.has('itemFilter') ? searchParams.get('itemFilter') : null;

  const queryString = buildQueryString(clipboardParam, pageParam, itemFilterParam);

  return (
    <>
      <div className="navbar">
        <div className="navbar-content">
          <span className="app-title">React Todo</span>
          <div className="nav-links">
            <NavLink to={`/${queryString}`} end>
              Home
            </NavLink>
            <NavLink to={`/about${queryString}`} end>
              About
            </NavLink>
            <Login />
          </div>
        </div>
      </div>
    </>
  )
}

export default Navbar;