import { Canvas, useThree } from "@react-three/fiber";
import vertexShader from './shaders/vertex.glsl'
import fragmentShader from './shaders/fragment.glsl'


const Fragment = () => {
  const viewport = useThree(state => state.viewport)
  return (
    <mesh position={[0, 0, 0]} scale={[viewport.width, viewport.height, 1]}>
      <planeGeometry args={[1, 1]} />
      <shaderMaterial
        fragmentShader={fragmentShader}
        vertexShader={vertexShader}
      />
    </mesh>
  );
};

const Scene = () => {
  return (
    <Canvas camera={{ position: [0.0, 0.0, 1.0] }}>
      <Fragment />
    </Canvas>
  );
};

function App() {
  return (
    <Scene />
  )
}

export default App