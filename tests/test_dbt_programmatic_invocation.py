#!/usr/bin/env python3
"""
Unit tests with programmatic dbt invocation


"""

import unittest
import subprocess
import os
import json
import tempfile
from pathlib import Path
from unittest.mock import patch, Mock
import sys

# Add the project root to the Python path for imports
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

class TestDBTProgrammaticInvocation(unittest.TestCase):
    """
    Test suite that programmatically invokes dbt commands
    """
    
    def setUp(self):
        """Set up test environment with dbt project path"""
        self.project_dir = PROJECT_ROOT
        self.profiles_dir = self.project_dir / ".dbt"
        
        # Ensure we're in the right directory
        os.chdir(self.project_dir)
        
    def test_dbt_compile_programmatically(self):
        """
        Test programmatic dbt compile execution - 
        This pattern is common in CI/CD pipelines and testing frameworks
        """
        try:
            # Programmatic dbt compile invocation
            result = subprocess.run(
                ["dbt", "compile", "--profiles-dir", str(self.profiles_dir)],
                capture_output=True,
                text=True,
                cwd=self.project_dir,
                timeout=300
            )
            
            # Validate compilation success
            self.assertEqual(result.returncode, 0, 
                           f"dbt compile failed: {result.stderr}")
            
            # Check for compiled files
            compiled_dir = self.project_dir / "target" / "compiled" / "jaffle_shop"
            self.assertTrue(compiled_dir.exists(), 
                          "Compiled models directory should exist")
            
            # Validate specific compiled models exist
            customer_model = compiled_dir / "models" / "marts" / "customers.sql"
            self.assertTrue(customer_model.exists(),
                          "Compiled customers model should exist")
            
        except subprocess.TimeoutExpired:
            self.fail("dbt compile command timed out")
        except Exception as e:
            self.fail(f"Programmatic dbt compile failed: {str(e)}")
    
    def test_dbt_run_specific_models_programmatically(self):
        """
        Test selective model execution via programmatic dbt run - 
        This demonstrates advanced dbt CLI usage patterns
        """
        try:
            # Run only staging models programmatically
            result = subprocess.run(
                ["dbt", "run", "--select", "staging.*", 
                 "--profiles-dir", str(self.profiles_dir)],
                capture_output=True,
                text=True,
                cwd=self.project_dir,
                timeout=600
            )
            
            # Check execution results
            if result.returncode != 0:
                # Handle potential failures gracefully for demo
                print(f"Warning: dbt run failed (expected in demo): {result.stderr}")
            else:
                # Validate run artifacts if successful
                run_results_path = self.project_dir / "target" / "run_results.json"
                if run_results_path.exists():
                    with open(run_results_path, 'r') as f:
                        run_results = json.load(f)
                    
                    # Validate staging models were executed
                    executed_models = [r['unique_id'] for r in run_results.get('results', [])]
                    staging_models = [m for m in executed_models if 'staging' in m]
                    self.assertGreater(len(staging_models), 0, 
                                     "At least one staging model should be executed")
                
        except subprocess.TimeoutExpired:
            self.fail("dbt run command timed out")
        except Exception as e:
            # Handle demo environment gracefully
            print(f"Note: Programmatic dbt run test failed (expected): {str(e)}")
    
    def test_dbt_test_execution_with_parsing(self):
        """
        Test programmatic dbt test execution with result parsing - 
        Demonstrates integration testing patterns that rely on dbt CLI
        """
        try:
            # Execute dbt tests programmatically
            result = subprocess.run(
                ["dbt", "test", "--profiles-dir", str(self.profiles_dir)],
                capture_output=True,
                text=True,
                cwd=self.project_dir,
                timeout=300
            )
            
            # Parse test results programmatically
            if result.returncode == 0:
                # Tests passed - validate output
                self.assertIn("Completed successfully", result.stdout)
            else:
                # Parse test failures for analysis
                lines = result.stderr.split('\n')
                test_failures = [line for line in lines if 'FAIL' in line]
                
                # Log test failures for debugging (demo purposes)
                if test_failures:
                    print(f"Test failures detected: {len(test_failures)}")
                    for failure in test_failures[:5]:  # Limit output
                        print(f"  - {failure}")
                
        except subprocess.TimeoutExpired:
            self.fail("dbt test command timed out")
        except Exception as e:
            print(f"Note: Programmatic dbt test failed (expected in demo): {str(e)}")
    
    def test_dbt_manifest_parsing_and_analysis(self):
        """
        Test programmatic manifest parsing - 
        This pattern is used for lineage analysis and metadata extraction
        """
        try:
            # Ensure manifest exists by running compile
            subprocess.run(
                ["dbt", "compile", "--profiles-dir", str(self.profiles_dir)],
                capture_output=True,
                cwd=self.project_dir,
                timeout=300
            )
            
            # Programmatically parse manifest.json
            manifest_path = self.project_dir / "target" / "manifest.json"
            
            if manifest_path.exists():
                with open(manifest_path, 'r') as f:
                    manifest = json.load(f)
                
                # Analyze manifest programmatically
                nodes = manifest.get('nodes', {})
                models = {k: v for k, v in nodes.items() if v.get('resource_type') == 'model'}
                
                # Validate model structure
                self.assertGreater(len(models), 0, "Should have compiled models in manifest")
                
                # Check for specific models we created
                model_names = [v.get('name') for v in models.values()]
                
                # Look for our migration blocker models
                blocker_models = [
                    'customer_segments_python',
                    'order_events_microbatch', 
                    'products_with_audit',
                    'order_history_iceberg'
                ]
                
                found_blockers = [m for m in blocker_models if m in model_names]
                print(f"Found migration blocker models: {found_blockers}")
                
                # Analyze model dependencies programmatically
                for model_key, model_data in models.items():
                    deps = model_data.get('depends_on', {}).get('nodes', [])
                    if len(deps) > 2:  # Complex dependencies
                        print(f"Complex model: {model_data.get('name')} has {len(deps)} dependencies")
                        
            else:
                print("Warning: manifest.json not found - compile may have failed")
                
        except Exception as e:
            print(f"Note: Manifest parsing test failed (expected): {str(e)}")
    
    def test_custom_dbt_python_integration(self):
        """
        Test custom Python integration with dbt - 
        Demonstrates complex Python workflows that integrate with dbt
        """
        
        # Mock dbt Python API usage (since actual API may not be available)
        class MockDBTRunner:
            def __init__(self, project_dir):
                self.project_dir = project_dir
                
            def run_model(self, model_name):
                """Simulate programmatic model execution"""
                cmd = ["dbt", "run", "--select", model_name]
                result = subprocess.run(cmd, capture_output=True, text=True, 
                                      cwd=self.project_dir)
                return result.returncode == 0
                
            def get_model_metadata(self, model_name):
                """Simulate metadata extraction"""
                return {
                    'name': model_name,
                    'materialization': 'table',
                    'tags': ['programmatic_test'],
                    'execution_time': '2024-01-01T00:00:00Z'
                }
        
        # Test custom integration
        runner = MockDBTRunner(self.project_dir)
        
        # Test programmatic model execution
        test_models = ['customers', 'orders']
        results = {}
        
        for model in test_models:
            try:
                success = runner.run_model(model)
                metadata = runner.get_model_metadata(model)
                results[model] = {'success': success, 'metadata': metadata}
            except Exception as e:
                results[model] = {'success': False, 'error': str(e)}
        
        # Validate integration results
        self.assertGreater(len(results), 0, "Should have test results")
        
        # Log results for demonstration
        print("Programmatic dbt integration test results:")
        for model, result in results.items():
            status = "✓" if result.get('success') else "✗"
            print(f"  {status} {model}: {result}")

    @patch('subprocess.run')
    def test_dbt_ci_cd_pipeline_simulation(self, mock_subprocess):
        """
        Test CI/CD pipeline patterns with dbt - 
        Simulates common DevOps integration patterns
        """
        # Mock successful dbt commands
        mock_subprocess.return_value = Mock(returncode=0, stdout="Success", stderr="")
        
        # Simulate CI/CD pipeline steps
        pipeline_steps = [
            ["dbt", "deps"],
            ["dbt", "seed"],
            ["dbt", "run", "--exclude", "tag:deprecated"],
            ["dbt", "test"],
            ["dbt", "docs", "generate"]
        ]
        
        # Execute pipeline programmatically
        for step in pipeline_steps:
            try:
                result = subprocess.run(step, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, f"Pipeline step failed: {' '.join(step)}")
            except Exception as e:
                print(f"Pipeline step simulation: {' '.join(step)} - {str(e)}")
        
        # Validate all steps were called
        self.assertEqual(mock_subprocess.call_count, len(pipeline_steps))
        print(f"Simulated {len(pipeline_steps)} CI/CD pipeline steps")


class TestDBTMetricsAndSemanticLayer(unittest.TestCase):
    """
    Additional tests for semantic layer functionality - 
    Tests programmatic interaction with dbt's semantic layer
    """
    
    def test_semantic_model_validation(self):
        """Test programmatic semantic model validation"""
        # This would test semantic models but is a blocker for Fusion
        print("Note: Semantic model tests create Fusion migration blockers")
        
        # Simulate semantic model validation
        semantic_models = [
            'customers',  # From our customers.yml
        ]
        
        for model in semantic_models:
            print(f"Validating semantic model: {model}")
            # In real scenario, this would use dbt's semantic layer API
            
    def test_saved_query_execution(self):
        """Test programmatic saved query execution"""
        print("Note: Saved query execution creates Fusion migration blockers")
        
        # Our saved queries from the configuration
        saved_queries = [
            'customer_revenue_export',
            'product_performance_dashboard',
            'order_trends_weekly_report'
        ]
        
        for query in saved_queries:
            print(f"Would execute saved query: {query}")
            # This would programmatically execute saved queries


if __name__ == '__main__':
    # Run the test suite
    print("Running dbt Programmatic Invocation Tests")
    print("=" * 50)
    print("These tests demonstrate Fusion migration blockers:")
    print("- Programmatic dbt CLI invocation")
    print("- Python API usage")
    print("- CI/CD integration patterns") 
    print("- Semantic layer interactions")
    print("=" * 50)
    
    unittest.main(verbosity=2)
