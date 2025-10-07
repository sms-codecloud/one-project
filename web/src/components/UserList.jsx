import { FaEye, FaEdit, FaTrash, FaGripLinesVertical } from "react-icons/fa";
import { Link, useNavigate } from "react-router";
import useUserInfo from "../context/userContext";
import { useModal } from "../context/modalContext";

const UsersList = () => {
  const { userList, deleteUser, isLoading } = useUserInfo();
  const { openConfirm } = useModal();
  const navigate = useNavigate();

  const handleDelete = (id) => {
    openConfirm("Are you sure you want to delete this user?", () => {
      deleteUser(id);
    });
  };

  const handleAddUser = () => {
    navigate("/add-user");
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: "10px",
        }}
      >
        <h3>Users List</h3>
        <button className="add-user-btn" onClick={() => handleAddUser()}>
          Add User
        </button>
      </div>

      <div>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {userList &&
              userList.map((ul) => (
                <tr key={ul.id}>
                  <td>{ul.name}</td>
                  <td>{ul.email}</td>
                  <td>{ul.phone}</td>
                  <td className="action-icons">
                    <Link to={`/users/${ul.id}`} title="View Details">
                      <FaEye color="gray" />
                    </Link>

                    <FaGripLinesVertical />

                    <Link to={`/users/${ul.id}/edit`} title="Edit">
                      <FaEdit color="#007bff" />
                    </Link>

                    <FaGripLinesVertical />

                    <FaTrash
                      color="red"
                      style={{ cursor: "pointer" }}
                      onClick={() => handleDelete(ul.id)}
                      title="Delete"
                    />
                  </td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>
    </>
  );
};

export default UsersList;
