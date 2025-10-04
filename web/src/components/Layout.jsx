import { Outlet } from "react-router-dom";
import ConfirmModal from "./ConfirmModal";
import { useModal } from "../context/modalContext";

const Layout = () => {
  const { isOpen, message, confirm, closeConfirm } = useModal();

  return (
    <>
      <ConfirmModal
        isOpen={isOpen}
        message={message}
        onConfirm={confirm}
        onClose={closeConfirm}
      />
      <Outlet />
    </>
  );
};

export default Layout;
