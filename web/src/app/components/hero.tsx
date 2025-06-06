import React from "react";
import Image from "next/image";

export const Hero =() => {
  return (
    <div className="h-screen bg-[#282828]">
      <h1 className="text-[10rem] font-extralight tracking-tight">FLOREVER</h1>
      <Image src={"/plant.png"} alt="plant" width={1200} height={500} className="" />
    </div>
  );
}
