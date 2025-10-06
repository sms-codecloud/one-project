import { FaEye, FaEdit, FaTrash, FaGripLinesVertical } from "react-icons/fa";
import { Link, Outlet } from "react-router";
import useUserInfo from "../context/userContext";
import { useModal } from "../context/modalContext";

const UsersList = () => {
  const { userList, deleteUser, isLoading } = useUserInfo();
  const { openConfirm } = useModal();

  const handleDelete = (id) => {
    openConfirm("Are you sure you want to delete this user?", () => {
      deleteUser(id);
    });
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <>
      <h3>Users List</h3>
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
