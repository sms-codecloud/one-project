import { createContext, useContext, useEffect, useState } from "react";
import { BASE_URL } from "../utils/constants.jsx";

export const UserContext = createContext();

export const UserProvider = ({ children }) => {
  const [userList, setUserList] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch(`${BASE_URL}/users`);
        const data = await response.json();
        setUserList(data);
        setIsLoading(false);
      } catch (error) {
        console.error("Failed to fetch users:", error);
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  const getUserById = async (id) => {
    // First check local state
    const existing = userList.find((user) => user.id === Number(id));
    if (existing) return existing;

    try {
      const res = await fetch(`${BASE_URL}/users/${id}`);
      const data = await res.json();
      return data;
    } catch (error) {
      console.error("Failed to fetch user by ID:", error);
      return null;
    }
  };

  const deleteUser = (id) => {
    setUserList((prevList) => prevList.filter((user) => user.id !== id));
  };

  return (
    <UserContext.Provider
      value={{ userList, deleteUser, isLoading, getUserById }}
    >
      {children}
    </UserContext.Provider>
  );
};

const useUserInfo = () => {
  return useContext(UserContext);
};

export default useUserInfo;
