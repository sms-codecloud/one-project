import { RouterProvider, createBrowserRouter } from "react-router-dom";
import { UserProvider } from "./context/userContext";
import { ModalProvider } from "./context/modalContext";
import Layout from "./components/Layout";
import UserDetails from "./components/UserDetails";
import UsersList from "./components/UserList";
import UserEdit from "./components/UserEdit";
import Error from "./components/Error";

function App() {
  const appRouter = createBrowserRouter([
    {
      path: "/",
      element: <Layout />,
      errorElement: <Error />,
      children: [
        { path: "/", element: <UsersList /> }, // /users
        { path: "users/:id", element: <UserDetails /> }, // /user details
        { path: "users/:id/edit", element: <UserEdit /> }, // /user eidt
      ],
    },
  ]);

  return (
    <>
      <UserProvider>
        <ModalProvider>
          <RouterProvider router={appRouter} />
        </ModalProvider>
      </UserProvider>
    </>
  );
}

export default App;
