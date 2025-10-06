import { Link, useParams } from "react-router";
import "./styles/userEdit.css";
import { useState } from "react";

const AddUser = () => {
  const [addr, setAddr] = useState("");
  return (
    <div className="user-edit-card">
      <h3>Add User</h3>
      <form>
        <div className="section">
          <label>Name</label>
          <input name="name" value="" />

          <label>Username</label>
          <input name="username" value="" />

          <label>Email</label>
          <input name="email" value="" />

          <label>Phone</label>
          <input name="phone" value="" />
        </div>

        <div className="section">
          <h4>Address</h4>
          <textarea
            name="address.street"
            value={addr}
            onChange={(e) => setAddr(e.target.value)}
          />
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

export default AddUser;
