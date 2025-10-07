import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { api } from "./api";

function App() {
  const [students, setStudents] = useState([]);
  const [form, setForm] = useState({ name: "", email: "", age: 18 });
  const [error, setError] = useState("");

  const load = async () => {
    try {
      setStudents(await api("/students"));
    } catch (e) {
      setError(e.message || String(e));
    }
  };

  useEffect(() => { load(); }, []);

  const submit = async (e) => {
    e.preventDefault();
    setError("");
    try {
      await api("/students", { method: "POST", body: form });
      setForm({ name: "", email: "", age: 18 });
      await load();
    } catch (e) { setError(e.message || String(e)); }
  };

  const remove = async (id) => {
    setError("");
    try { await api(`/students/${id}`, { method: "DELETE" }); await load(); }
    catch (e) { setError(e.message || String(e)); }
  };

  return (
    <div style={{fontFamily:"system-ui,Segoe UI,Roboto,Arial",maxWidth:800,margin:"40px auto"}}>
      <h1>Student Registration</h1>

      {error && <p style={{color:"crimson"}}>Error: {error}</p>}

      <form onSubmit={submit} style={{display:"grid",gap:8,maxWidth:400}}>
        <input placeholder="Name"  value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} required/>
        <input placeholder="Email" value={form.email} onChange={e=>setForm(f=>({...f,email:e.target.value}))} type="email" required/>
        <input placeholder="Age"   value={form.age} onChange={e=>setForm(f=>({...f,age:+e.target.value||0}))} type="number" min="1" />
        <button type="submit">Add</button>
      </form>

      <h2 style={{marginTop:24}}>Students</h2>
      <ul>
        {students.map(s => (
          <li key={s.id} style={{marginBottom:6}}>
            {s.name} ({s.email}, {s.age}){" "}
            <button onClick={()=>remove(s.id)}>Delete</button>
          </li>
        ))}
      </ul>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
