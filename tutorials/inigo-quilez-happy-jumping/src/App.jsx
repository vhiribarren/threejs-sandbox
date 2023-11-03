import { useMemo, useRef, useEffect, useState } from "react";
import { Canvas, useThree, useFrame } from "@react-three/fiber";
import { Stats } from '@react-three/drei'
import vertexShader from './shaders/vertex.glsl'
import fragmentShader from './shaders/inigo_quilez_happy_jumping.glsl'

export default App;


function App() {
  return (
    <Scene />
  );
}


function Scene() {
  return (
    <Canvas camera={{ position: [0.0, 0.0, 1.0] }}>
      <Fragment />
      <Stats />
    </Canvas>
  );
}


function Fragment() {
  
  const meshRef = useRef();
  const [keys, setKeys] = useState(new Set());
  const viewport = useThree(state => state.viewport);
  const uniforms = useMemo(
    () => ({
      u_time: {
        value: 1.0,
      },
      u_offset_horizontal: {
        value: 0.0,
      },
    }),
    []
  );

  useFrame((state, delta) => {
    const { clock } = state;
    meshRef.current.material.uniforms.u_time.value = clock.getElapsedTime();
    if (keys.has("ArrowLeft")) {
      meshRef.current.material.uniforms.u_offset_horizontal.value -= delta;
    }
    if (keys.has("ArrowRight")) {
      meshRef.current.material.uniforms.u_offset_horizontal.value += delta;
    }
  });

  useEffect(() => {
    // To take into account dynamic shader update
    meshRef.current.material.needsUpdate = true;

    const handleKeyDown = event => {
      setKeys(prevKeys => new Set(prevKeys).add(event.code));
    };
    const handleKeyUp = event => {
      setKeys(prevKeys => {
        prevKeys.delete(event.code);
        return new Set(prevKeys);
      });
    };
    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("keyup", handleKeyUp);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      window.removeEventListener("keyup", handleKeyUp);
    };
  }, []);

  return (
    <mesh ref={meshRef} position={[0, 0, 0]} scale={[viewport.width, viewport.height, 1]}>
      <planeGeometry args={[1, 1]} />
      <shaderMaterial
        fragmentShader={fragmentShader}
        vertexShader={vertexShader}
        uniforms={uniforms}
      />
    </mesh>
  );
}