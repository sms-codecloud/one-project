import { Link, useParams } from "react-router";
import { useEffect, useState } from "react";
import "./styles/userDetails.css";
import useUserInfo from "../context/userContext";

const UserDetails = () => {
  const { id } = useParams();
  const { getUserById } = useUserInfo();
  const [user, setUser] = useState(null);

  useEffect(() => {
    const fetchUser = async () => {
      const data = await getUserById(id);
      setUser(data);
    };
    fetchUser();
  }, [id, getUserById]);

  if (!user) return <div>Loading...</div>;

  const { name, username, email, phone, address, company } = user;

  return (
    <div className="user-card">
      <h2>{name}</h2>
      <p>
        <strong>Username:</strong> {username}
      </p>
      <p>
        <strong>Email:</strong> {email}
      </p>
      <p>
        <strong>Phone:</strong> {phone}
      </p>
      <div className="section">
        <h3>Address</h3>
        <p>
          {address.street}, {address.suite}
        </p>
        <p>
          {address.city} - {address.zipcode}
        </p>
      </div>

      <div className="section">
        <Link to="/">Back to Home</Link>
      </div>
    </div>
  );
};

export default UserDetails;
