import { Link, useRouteError } from "react-router-dom";
import "./styles/error.css";

const Error = () => {
  const error = useRouteError();

  return (
    <div className="error-container">
      <h1>Oops!</h1>
      <p>Sorry, an unexpected error has occurred.</p>
      {error.status && (
        <p>
          <strong>Status:</strong> {error.status}
        </p>
      )}
      {error.statusText && (
        <p>
          <strong>Message:</strong> {error.statusText}
        </p>
      )}
      {/* {error.data && <pre>{JSON.stringify(error.data, null, 2)}</pre>} */}
      {error.data && <pre>{error.data}</pre>}
      <Link to="/" className="error-home-link">
        Back to Home
      </Link>
    </div>
  );
};

export default Error;
