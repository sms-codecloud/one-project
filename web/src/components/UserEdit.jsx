import { Link, useParams } from "react-router";
import "./styles/userEdit.css";
import useUserInfo from "../context/userContext";
import { useEffect, useState } from "react";

const UserEdit = () => {
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

  return (
    <div className="user-edit-card">
      <h3>Edit User</h3>
      <form>
        <div className="section">
          <label>Name</label>
          <input name="name" value={user?.name} />

          <label>Username</label>
          <input name="username" value={user?.username} />

          <label>Email</label>
          <input name="email" value={user?.email} />

          <label>Phone</label>
          <input name="phone" value={user?.phone} />
        </div>

        <div className="section">
          <h4>Address</h4>
          <label>Street</label>
          <input name="address.street" value={user?.address?.street} />

          <label>Suite</label>
          <input name="address.suite" value={user?.address?.suite} />

          <label>City</label>
          <input name="address.city" value={user?.address?.city} />

          <label>Zipcode</label>
          <input name="address.zipcode" value={user?.address?.zipcode} />
        </div>

        <div className="actions">
          <button type="submit">Save</button>
          <Link to="/" style={{ padding: "10px" }}>
            Back to List
          </Link>
        </div>
      </form>
    </div>
  );
};

export default UserEdit;
